const { getSupabase, isSupabaseConfigured } = require('./supabase');

const UNLINKED_POSTER_EMAIL = 'unlinked-listings@internal.bhandara.local';
let unlinkedPosterUserIdCache = null;

async function getUnlinkedPosterUserId(supabase) {
  if (unlinkedPosterUserIdCache) {
    return unlinkedPosterUserIdCache;
  }

  const { data: existing, error: lookupError } = await supabase
    .from('users')
    .select('id')
    .eq('email', UNLINKED_POSTER_EMAIL)
    .maybeSingle();

  if (lookupError) throw new Error(lookupError.message);
  if (existing?.id) {
    unlinkedPosterUserIdCache = existing.id;
    return existing.id;
  }

  const { data: created, error: createError } = await supabase.auth.admin.createUser({
    email: UNLINKED_POSTER_EMAIL,
    email_confirm: true,
    user_metadata: { full_name: 'Unlinked Listing' },
  });

  if (createError) throw new Error(createError.message);

  unlinkedPosterUserIdCache = created.user.id;
  return created.user.id;
}

async function backfillBhandaraOwner(supabase, bhandaraId, ownerId) {
  await supabase.from('bhandaras').update({ posted_by: ownerId }).eq('id', bhandaraId);
  return ownerId;
}

async function resolveBhandaraOwner(supabase, bhandara) {
  if (bhandara.posted_by) {
    return bhandara.posted_by;
  }

  const publisherName = (bhandara.publisher_name || '').trim();
  if (!publisherName) {
    return null;
  }

  const normalizedPublisher = publisherName.toLowerCase();

  const { data: users, error } = await supabase
    .from('users')
    .select('id, full_name, email');

  if (error) throw new Error(error.message);

  const exactNameMatches = (users || []).filter(
    (user) => (user.full_name || '').trim().toLowerCase() === normalizedPublisher,
  );
  if (exactNameMatches.length === 1) {
    return backfillBhandaraOwner(supabase, bhandara.id, exactNameMatches[0].id);
  }

  const partialNameMatches = (users || []).filter((user) => {
    const fullName = (user.full_name || '').trim().toLowerCase();
    if (!fullName) return false;
    return fullName.includes(normalizedPublisher) || normalizedPublisher.includes(fullName);
  });
  if (partialNameMatches.length === 1) {
    return backfillBhandaraOwner(supabase, bhandara.id, partialNameMatches[0].id);
  }

  const publisherCompact = normalizedPublisher.replace(/\s+/g, '');
  const emailMatches = (users || []).filter((user) => {
    const localPart = (user.email || '').split('@')[0].toLowerCase();
    const localCompact = localPart.replace(/[._-]/g, '');
    return (
      localPart === normalizedPublisher ||
      localCompact === publisherCompact ||
      localCompact.includes(publisherCompact) ||
      publisherCompact.includes(localCompact)
    );
  });
  if (emailMatches.length === 1) {
    return backfillBhandaraOwner(supabase, bhandara.id, emailMatches[0].id);
  }

  return null;
}

async function submitBhandaraReport({ bhandaraId, reporterId, reason }) {
  if (!isSupabaseConfigured()) {
    throw new Error('Reports require Supabase database');
  }

  const supabase = getSupabase();
  const trimmedReason = reason.trim();

  if (trimmedReason.length < 5) {
    throw new Error('Report reason must be at least 5 characters');
  }

  const { data: bhandara, error: bhandaraError } = await supabase
    .from('bhandaras')
    .select('id, posted_by, publisher_name')
    .eq('id', bhandaraId)
    .maybeSingle();

  if (bhandaraError) throw new Error(bhandaraError.message);

  if (!bhandara) {
    throw new Error('Bhandara not found');
  }

  let reportedUserId = await resolveBhandaraOwner(supabase, bhandara);

  if (!reportedUserId) {
    reportedUserId = await getUnlinkedPosterUserId(supabase);
  }

  if (reportedUserId === reporterId) {
    throw new Error('You cannot report your own Bhandara');
  }

  const { data: existing } = await supabase
    .from('bhandara_reports')
    .select('id')
    .eq('bhandara_id', bhandaraId)
    .eq('reporter_id', reporterId)
    .maybeSingle();

  if (existing) {
    throw new Error('You have already reported this Bhandara');
  }

  const { data: inserted, error: insertError } = await supabase
    .from('bhandara_reports')
    .insert({
      bhandara_id: bhandaraId,
      reporter_id: reporterId,
      reported_user_id: reportedUserId,
      reason: trimmedReason,
    })
    .select('id, created_at, reported_user_id')
    .single();

  if (insertError) throw new Error(insertError.message);

  const unlinkedPosterId = await getUnlinkedPosterUserId(supabase);
  let reportedUserReportCount = 0;
  let reportedUserBlocked = false;

  if (inserted.reported_user_id && inserted.reported_user_id !== unlinkedPosterId) {
    const { data: reportedUser } = await supabase
      .from('users')
      .select('report_count, is_blocked')
      .eq('id', inserted.reported_user_id)
      .maybeSingle();

    reportedUserReportCount = reportedUser?.report_count ?? 0;
    reportedUserBlocked = reportedUser?.is_blocked ?? false;
  }

  return {
    reportId: inserted.id,
    createdAt: inserted.created_at,
    reportedUserLinked: inserted.reported_user_id !== unlinkedPosterId,
    reportedUserReportCount,
    reportedUserBlocked,
  };
}

async function getUserBlockStatus(userId) {
  if (!isSupabaseConfigured()) {
    return { isBlocked: false, reportCount: 0, isAdmin: false };
  }

  const supabase = getSupabase();
  const { data, error } = await supabase
    .from('users')
    .select('is_blocked, report_count, is_admin')
    .eq('id', userId)
    .maybeSingle();

  if (error) throw new Error(error.message);

  return {
    isBlocked: data?.is_blocked ?? false,
    reportCount: data?.report_count ?? 0,
    isAdmin: data?.is_admin ?? false,
  };
}

async function getAllReportsForAdmin() {
  if (!isSupabaseConfigured()) {
    throw new Error('Reports require Supabase database');
  }

  const supabase = getSupabase();
  const { data: reports, error } = await supabase
    .from('bhandara_reports')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw new Error(error.message);
  if (!reports?.length) return [];

  const bhandaraIds = [...new Set(reports.map((r) => r.bhandara_id))];
  const userIds = [
    ...new Set(
      reports.flatMap((r) => [r.reporter_id, r.reported_user_id].filter(Boolean)),
    ),
  ];

  const { data: bhandaras, error: bhandaraError } = await supabase
    .from('bhandaras')
    .select('id, bhandara_name, village, pin_code')
    .in('id', bhandaraIds);

  if (bhandaraError) throw new Error(bhandaraError.message);

  const { data: users, error: usersError } = await supabase
    .from('users')
    .select('id, email, full_name, report_count, is_blocked')
    .in('id', userIds);

  if (usersError) throw new Error(usersError.message);

  const bhandaraMap = Object.fromEntries((bhandaras || []).map((b) => [b.id, b]));
  const userMap = Object.fromEntries((users || []).map((u) => [u.id, u]));

  const unlinkedPosterId = await getUnlinkedPosterUserId(supabase);

  return reports.map((report) => {
    const bhandara = bhandaraMap[report.bhandara_id] || {};
    const reporter = userMap[report.reporter_id] || {};
    const reported = userMap[report.reported_user_id] || {};
    const isUnlinkedPoster = report.reported_user_id === unlinkedPosterId;

    return {
      id: report.id,
      reason: report.reason,
      createdAt: report.created_at,
      bhandaraId: report.bhandara_id,
      bhandaraName: bhandara.bhandara_name || 'Unknown',
      bhandaraVillage: bhandara.village || '',
      bhandaraPinCode: bhandara.pin_code || '',
      reporterId: report.reporter_id,
      reporterEmail: reporter.email || '',
      reporterName: reporter.full_name || '',
      reportedUserId: report.reported_user_id,
      reportedUserEmail: isUnlinkedPoster ? '' : (reported.email || ''),
      reportedUserName: isUnlinkedPoster
          ? (bhandara.publisher_name || 'Unlinked listing')
          : (reported.full_name || 'Unknown'),
      reportedUserReportCount: isUnlinkedPoster ? 0 : (reported.report_count ?? 0),
      reportedUserBlocked: isUnlinkedPoster ? false : (reported.is_blocked ?? false),
    };
  });
}

async function getReportsGroupedByUserForAdmin() {
  const reports = await getAllReportsForAdmin();
  const supabase = getSupabase();
  const unlinkedPosterId = await getUnlinkedPosterUserId(supabase);
  const groups = new Map();

  for (const report of reports) {
    const userId = report.reportedUserId;
    if (!userId) continue;

    const isUnlinked = userId === unlinkedPosterId;
    const groupKey = userId;

    if (!groups.has(groupKey)) {
      groups.set(groupKey, {
        userId,
        name: report.reportedUserName,
        email: report.reportedUserEmail,
        reportCount: isUnlinked ? reports.filter((r) => r.reportedUserId === userId).length : report.reportedUserReportCount,
        isBlocked: isUnlinked ? false : report.reportedUserBlocked,
        canBlock: !isUnlinked,
        reports: [],
      });
    }

    groups.get(groupKey).reports.push(report);
  }

  return [...groups.values()].sort((a, b) => b.reports.length - a.reports.length);
}

async function setUserBlocked(userId, blocked) {
  if (!isSupabaseConfigured()) {
    throw new Error('User blocking requires Supabase database');
  }

  const supabase = getSupabase();
  const unlinkedPosterId = await getUnlinkedPosterUserId(supabase);

  if (userId === unlinkedPosterId) {
    throw new Error('Cannot block an unlinked listing placeholder account');
  }

  const { data: user, error: lookupError } = await supabase
    .from('users')
    .select('id, is_admin, email')
    .eq('id', userId)
    .maybeSingle();

  if (lookupError) throw new Error(lookupError.message);
  if (!user) throw new Error('User not found');

  if (user.is_admin && blocked) {
    throw new Error('Cannot block an admin account');
  }

  const { error } = await supabase
    .from('users')
    .update({ is_blocked: blocked })
    .eq('id', userId);

  if (error) throw new Error(error.message);

  return {
    userId,
    email: user.email,
    isBlocked: blocked,
  };
}

module.exports = {
  submitBhandaraReport,
  getUserBlockStatus,
  getAllReportsForAdmin,
  getReportsGroupedByUserForAdmin,
  setUserBlocked,
};
