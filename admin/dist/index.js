"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("./env"); // 必须第一个导入
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const database_1 = require("./config/database");
const auth_1 = __importDefault(require("./routes/auth"));
const users_1 = __importDefault(require("./routes/users"));
const messages_1 = __importDefault(require("./routes/messages"));
const inviteCodes_1 = __importDefault(require("./routes/inviteCodes"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3001;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// 路由
app.use('/api/auth', auth_1.default);
app.use('/api/users', users_1.default);
app.use('/api/messages', messages_1.default);
app.use('/api/invite-codes', inviteCodes_1.default);
// 静态文件（前端）
app.use(express_1.default.static('public'));
// 错误处理
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ error: '服务器内部错误' });
});
const start = async () => {
    await (0, database_1.initDatabase)();
    app.listen(PORT, () => {
        console.log(`Admin server running on http://localhost:${PORT}`);
    });
};
start();
