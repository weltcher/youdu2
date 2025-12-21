"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
// 先保存系统环境变量 PASSWORD2
const systemPassword2 = process.env.PASSWORD2;
const envPath = path_1.default.resolve(process.cwd(), '.env');
dotenv_1.default.config({ path: envPath, override: true });
// 恢复系统环境变量 PASSWORD2（不被 .env 覆盖）
if (systemPassword2) {
    process.env.PASSWORD2 = systemPassword2;
}
console.log('ENV loaded, PASSWORD2:', process.env.PASSWORD2 ? '***' : '(empty)');
