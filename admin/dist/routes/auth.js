"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const router = (0, express_1.Router)();
// 登录
router.post('/login', (req, res) => {
    const { username, password } = req.body;
    const adminUsername = process.env.ADMIN_USERNAME || 'admin';
    const adminPassword = process.env.ADMIN_PASSWORD || 'youdu123';
    if (username === adminUsername && password === adminPassword) {
        const token = jsonwebtoken_1.default.sign({ username }, process.env.JWT_SECRET || 'secret', { expiresIn: '24h' });
        return res.json({ token, username });
    }
    return res.status(401).json({ error: '用户名或密码错误' });
});
exports.default = router;
