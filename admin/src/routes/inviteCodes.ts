import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { pool } from '../config/database';
import { AuthRequest, authMiddleware } from '../middleware/auth';

const router = Router();
router.use(authMiddleware);

// 生成邀请码
const generateCode = (): string => {
  return uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase();
};

// 批量生成邀请码
router.post('/generate', async (req: AuthRequest, res: Response) => {
  const count = Math.min(parseInt(req.body.count) || 10, 1000);
  const totalCount = parseInt(req.body.total_count) || 1;
  const codes: string[] = [];
  const existingCodes = new Set<string>();

  // 获取已存在的邀请码
  const existing = await pool.query('SELECT code FROM invite_codes');
  existing.rows.forEach((row: { code: string }) => existingCodes.add(row.code));

  // 生成不重复的邀请码
  while (codes.length < count) {
    const code = generateCode();
    if (!existingCodes.has(code) && !codes.includes(code)) {
      codes.push(code);
    }
  }

  // 批量插入
  const values = codes.map((_, i) => `($${i * 2 + 1}, $${i * 2 + 2})`).join(',');
  const params: any[] = [];
  codes.forEach(code => {
    params.push(code, totalCount);
  });
  await pool.query(`INSERT INTO invite_codes (code, total_count) VALUES ${values}`, params);

  res.json({ message: `成功生成 ${count} 个邀请码`, codes });
});

// 邀请码列表
router.get('/', async (req: AuthRequest, res: Response) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = parseInt(req.query.limit as string) || 20;
  const status = req.query.status as string;
  const code = req.query.code as string || '';
  const username = req.query.username as string || '';
  const fullname = req.query.fullname as string || '';
  const email = req.query.email as string || '';
  const offset = (page - 1) * limit;

  let whereClause = 'WHERE 1=1';
  const params: any[] = [];
  let paramIndex = 1;

  // 状态筛选：根据 total_count 和 used_count 判断
  if (status === 'used') {
    whereClause += ` AND ic.total_count <= ic.used_count`;
  } else if (status === 'unused') {
    whereClause += ` AND ic.total_count > ic.used_count`;
  }

  if (code) {
    whereClause += ` AND ic.code ILIKE $${paramIndex}`;
    params.push(`%${code}%`);
    paramIndex++;
  }

  // 用户名、昵称、邮箱筛选需要在HAVING子句中处理（因为一个邀请码可能被多个用户使用）
  let havingClause = '';
  const havingConditions: string[] = [];
  if (username) {
    havingConditions.push(`STRING_AGG(u.username, ', ') ILIKE $${paramIndex}`);
    params.push(`%${username}%`);
    paramIndex++;
  }

  if (fullname) {
    havingConditions.push(`STRING_AGG(u.full_name, ', ') ILIKE $${paramIndex}`);
    params.push(`%${fullname}%`);
    paramIndex++;
  }

  if (email) {
    havingConditions.push(`STRING_AGG(u.email, ', ') ILIKE $${paramIndex}`);
    params.push(`%${email}%`);
    paramIndex++;
  }

  if (havingConditions.length > 0) {
    havingClause = ` HAVING ${havingConditions.join(' AND ')}`;
  }

  // 使用子查询来获取总数
  const countQuery = `
    SELECT COUNT(*) FROM (
      SELECT ic.id
      FROM invite_codes ic
      LEFT JOIN invite_code_usages icu ON icu.invite_code_id = ic.id
      LEFT JOIN users u ON u.id = icu.user_id
      ${whereClause}
      GROUP BY ic.id
      ${havingClause}
    ) sub
  `;
  const countResult = await pool.query(countQuery, params);
  const total = parseInt(countResult.rows[0].count);

  params.push(limit, offset);
  const result = await pool.query(
    `SELECT ic.id, ic.code, ic.status, ic.created_at, ic.remark, ic.total_count, ic.used_count,
            STRING_AGG(DISTINCT u.username, ', ') as used_by_username,
            STRING_AGG(DISTINCT u.full_name, ', ') as used_by_fullname,
            STRING_AGG(DISTINCT u.email, ', ') as used_by_email
     FROM invite_codes ic
     LEFT JOIN invite_code_usages icu ON icu.invite_code_id = ic.id
     LEFT JOIN users u ON u.id = icu.user_id
     ${whereClause}
     GROUP BY ic.id, ic.code, ic.status, ic.created_at, ic.remark, ic.total_count, ic.used_count
     ${havingClause}
     ORDER BY ic.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
    params
  );

  res.json({ data: result.rows, total, page, limit, totalPages: Math.ceil(total / limit) });
});

// 删除邀请码
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  await pool.query('DELETE FROM invite_codes WHERE id = $1', [id]);
  res.json({ message: '邀请码已删除' });
});

// 更新邀请码备注
router.put('/:id/remark', async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { remark } = req.body;
  await pool.query('UPDATE invite_codes SET remark = $1 WHERE id = $2', [remark || null, id]);
  res.json({ message: '备注已更新' });
});

// 更新邀请码总次数
router.put('/:id/total-count', async (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { total_count } = req.body;
  
  // 获取当前已使用次数
  const current = await pool.query('SELECT used_count FROM invite_codes WHERE id = $1', [id]);
  if (current.rows.length === 0) {
    return res.status(404).json({ error: '邀请码不存在' });
  }
  
  const usedCount = current.rows[0].used_count || 0;
  if (total_count < usedCount) {
    return res.status(400).json({ error: `总次数不能小于已使用次数(${usedCount})` });
  }
  
  // 更新总次数，同时根据是否用完更新状态
  const newStatus = total_count <= usedCount ? 'used' : 'unused';
  await pool.query(
    'UPDATE invite_codes SET total_count = $1, status = $2 WHERE id = $3', 
    [total_count, newStatus, id]
  );
  res.json({ message: '总次数已更新' });
});

// 统计
router.get('/stats', async (_req: AuthRequest, res: Response) => {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE total_count > used_count) as unused,
      COUNT(*) FILTER (WHERE total_count <= used_count) as used
    FROM invite_codes
  `);
  res.json(result.rows[0]);
});

export default router;
