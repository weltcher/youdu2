import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/database';
import { AuthRequest, authMiddleware } from '../middleware/auth';

const router = Router();
router.use(authMiddleware);

// 密码加盐配置（与 auth.ts 保持一致）
const PASSWORD_PREFIX = 'F3w^t4';
const PASSWORD_SUFFIX = 'w9Ae712';

// 获取管理员列表
router.get('/', async (req: AuthRequest, res: Response) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = parseInt(req.query.limit as string) || 20;
  const offset = (page - 1) * limit;

  const countResult = await pool.query('SELECT COUNT(*) FROM admin_user');
  const total = parseInt(countResult.rows[0].count);

  const result = await pool.query(
    `SELECT id, username, created_at, last_login_at 
     FROM admin_user 
     ORDER BY created_at DESC 
     LIMIT $1 OFFSET $2`,
    [limit, offset]
  );

  res.json({ 
    data: result.rows, 
    total, 
    page, 
    limit, 
    totalPages: Math.ceil(total / limit) 
  });
});

// 添加管理员
router.post('/', async (req: AuthRequest, res: Response) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: '用户名和密码不能为空' });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: '密码长度至少6位' });
  }

  try {
    // 检查用户名是否已存在
    const existing = await pool.query(
      'SELECT id FROM admin_user WHERE username = $1',
      [username]
    );
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: '用户名已存在' });
    }

    // 加密密码（与 auth.ts 保持一致的加盐方式）
    const saltedPassword = PASSWORD_PREFIX + password + PASSWORD_SUFFIX;
    const hashedPassword = await bcrypt.hash(saltedPassword, 10);

    await pool.query(
      'INSERT INTO admin_user (username, password, created_at) VALUES ($1, $2, CURRENT_TIMESTAMP)',
      [username, hashedPassword]
    );

    res.json({ message: '管理员添加成功' });
  } catch (error) {
    console.error('Add admin error:', error);
    res.status(500).json({ error: '添加失败' });
  }
});

// 修改管理员密码
router.put('/:id/password', async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { password } = req.body;

  if (!password || password.length < 6) {
    return res.status(400).json({ error: '密码长度至少6位' });
  }

  try {
    const saltedPassword = PASSWORD_PREFIX + password + PASSWORD_SUFFIX;
    const hashedPassword = await bcrypt.hash(saltedPassword, 10);

    const result = await pool.query(
      'UPDATE admin_user SET password = $1 WHERE id = $2',
      [hashedPassword, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: '管理员不存在' });
    }

    res.json({ message: '密码修改成功' });
  } catch (error) {
    console.error('Update password error:', error);
    res.status(500).json({ error: '修改失败' });
  }
});

// 删除管理员
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const currentUserId = req.admin?.id;

  // 不能删除自己
  if (parseInt(id) === currentUserId) {
    return res.status(400).json({ error: '不能删除当前登录的账号' });
  }

  try {
    // 检查是否是最后一个管理员
    const countResult = await pool.query('SELECT COUNT(*) FROM admin_user');
    if (parseInt(countResult.rows[0].count) <= 1) {
      return res.status(400).json({ error: '至少保留一个管理员账号' });
    }

    const result = await pool.query('DELETE FROM admin_user WHERE id = $1', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ error: '管理员不存在' });
    }

    res.json({ message: '管理员已删除' });
  } catch (error) {
    console.error('Delete admin error:', error);
    res.status(500).json({ error: '删除失败' });
  }
});

export default router;
