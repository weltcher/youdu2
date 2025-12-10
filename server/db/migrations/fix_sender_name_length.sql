-- 修复私聊消息表中sender_name和receiver_name字段长度限制
-- 从VARCHAR(50)扩大到VARCHAR(100)，与群组消息表和用户表保持一致

-- 扩大sender_name字段长度
ALTER TABLE messages ALTER COLUMN sender_name TYPE character varying(100);

-- 扩大receiver_name字段长度  
ALTER TABLE messages ALTER COLUMN receiver_name TYPE character varying(100);

-- 添加注释说明修改原因
COMMENT ON COLUMN messages.sender_name IS 'Sender username (expanded from 50 to 100 characters to match user full_name length)';
COMMENT ON COLUMN messages.receiver_name IS 'Receiver username (expanded from 50 to 100 characters to match user full_name length)';
