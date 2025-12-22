import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { authenticator } from 'otplib';
import { pool } from '../config/database';

const router = Router();

// 密码加盐配置
const PASSWORD_PREFIX = 'F3w^t4';
const PASSWORD_SUFFIX = 'w9Ae712';

// 登录 - 第一步：验证用户名密码
router.post('/login', async (req: Request, res: Response) => {
  const { username, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT id, username, password FROM admin_user WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    const user = result.rows[0];
    const saltedPassword = PASSWORD_PREFIX + password + PASSWORD_SUFFIX;
    const isValid = await bcrypt.compare(saltedPassword, user.password);

    if (!isValid) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    // 生成临时 token，用于 2FA 验证
    const tempToken = jwt.sign(
      { id: user.id, username: user.username, type: '2fa_pending' },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '5m' }
    );

    return res.json({ tempToken, require2FA: true });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ error: '服务器错误' });
  }
});

// 2FA 验证 - 第二步
router.post('/verify-2fa', async (req: Request, res: Response) => {
  const { tempToken, code } = req.body;

  try {
    // 验证临时 token
    const decoded = jwt.verify(tempToken, process.env.JWT_SECRET || 'secret') as any;

    if (decoded.type !== '2fa_pending') {
      return res.status(401).json({ error: '无效的验证请求' });
    }

    // 获取 Google Auth 密钥，去掉填充符并转大写
    let googleAuthSecret = process.env.GOOGLE_AUTH;
    if (!googleAuthSecret) {
      return res.status(500).json({ error: '2FA 未配置' });
    }
    // 标准化密钥：去掉填充符 = 和空格，转大写
    googleAuthSecret = googleAuthSecret.replace(/[=\s]/g, '').toUpperCase();

    // 调试日志
    const expectedCode = authenticator.generate(googleAuthSecret);
    console.log('2FA Debug:', {
      inputCode: code,
      expectedCode: expectedCode,
      secret: googleAuthSecret.substring(0, 4) + '****',
      secretLength: googleAuthSecret.length,
    });

    // 使用 otplib 验证 TOTP 码，设置时间窗口容差
    authenticator.options = { window: 1 };
    const isValid = authenticator.verify({ token: code, secret: googleAuthSecret });

    if (!isValid) {
      return res.status(401).json({ error: '验证码错误' });
    }

    // 获取上次登录时间（转换为 ISO 格式）
    const userResult = await pool.query(
      "SELECT last_login_at AT TIME ZONE 'UTC' as last_login_at FROM admin_user WHERE id = $1",
      [decoded.id]
    );
    const lastLoginAt = userResult.rows[0]?.last_login_at
      ? new Date(userResult.rows[0].last_login_at).toISOString()
      : null;

    // 更新最近登录时间
    await pool.query(
      'UPDATE admin_user SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1',
      [decoded.id]
    );

    // 生成正式 token
    const token = jwt.sign(
      { id: decoded.id, username: decoded.username },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '24h' }
    );

    return res.json({ token, username: decoded.username, lastLoginAt });
  } catch (error) {
    console.error('2FA verify error:', error);
    return res.status(401).json({ error: '验证失败' });
  }
});

export default router;
