const { getSupabase } = require('./supabase');

async function verifyAuthToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Login required' });
  }

  try {
    const supabase = getSupabase();
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data.user) {
      return res.status(401).json({ success: false, message: 'Invalid or expired session' });
    }

    req.authUser = data.user;
    req.accessToken = token;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: error.message });
  }
}

async function syncAuthUserProfile(supabase, authUser) {
  const email = authUser.email;
  if (!email) return;

  const metadata = authUser.user_metadata || {};
  const fullName = metadata.full_name || metadata.name || null;
  const avatarUrl = metadata.avatar_url || metadata.picture || null;

  const { error } = await supabase.from('users').upsert(
    {
      id: authUser.id,
      email,
      full_name: fullName,
      avatar_url: avatarUrl,
      last_login_at: new Date().toISOString(),
    },
    { onConflict: 'id' },
  );

  if (error) throw new Error(error.message);
}

async function requireActiveUser(req, res, next) {
  try {
    const supabase = getSupabase();
    await syncAuthUserProfile(supabase, req.authUser);

    const { data, error } = await supabase
      .from('users')
      .select('is_blocked')
      .eq('id', req.authUser.id)
      .maybeSingle();

    if (error) throw new Error(error.message);

    if (data?.is_blocked) {
      return res.status(403).json({
        success: false,
        message: 'Your account is blocked due to multiple reports',
        blocked: true,
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function requireAdmin(req, res, next) {
  try {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('users')
      .select('is_admin, is_blocked')
      .eq('id', req.authUser.id)
      .maybeSingle();

    if (error) throw new Error(error.message);

    if (data?.is_blocked) {
      return res.status(403).json({
        success: false,
        message: 'Your account is blocked due to multiple reports',
        blocked: true,
      });
    }

    if (!data?.is_admin) {
      return res.status(403).json({ success: false, message: 'Admin access required' });
    }

    next();
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function optionalAuthToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    next();
    return;
  }

  try {
    const supabase = getSupabase();
    const { data, error } = await supabase.auth.getUser(token);

    if (!error && data.user) {
      req.authUser = data.user;
      req.accessToken = token;
    }
  } catch (_) {}

  next();
}

module.exports = {
  verifyAuthToken,
  optionalAuthToken,
  requireActiveUser,
  requireAdmin,
  syncAuthUserProfile,
};
