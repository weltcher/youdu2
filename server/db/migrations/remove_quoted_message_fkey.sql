-- 移除 group_messages 表的 quoted_message_id 外键约束
-- 原因：引用消息的ID可能来自客户端本地数据库，不一定存在于服务器数据库中
-- 这会导致插入失败，影响引用消息功能的正常使用

ALTER TABLE public.group_messages
DROP CONSTRAINT IF EXISTS group_messages_quoted_message_id_fkey;

-- 同样移除 messages 表的外键约束（如果存在）
ALTER TABLE public.messages
DROP CONSTRAINT IF EXISTS messages_quoted_message_id_fkey;

-- 移除 file_assistant_messages 表的外键约束（如果存在）
ALTER TABLE public.file_assistant_messages
DROP CONSTRAINT IF EXISTS file_assistant_messages_quoted_message_id_fkey;
