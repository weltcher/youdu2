// 自动判断 API 路径：如果当前路径包含 /admin，则使用 /admin/api，否则使用 /api
const API_BASE = window.location.pathname.startsWith('/admin') ? '/admin/api' : '/api';
let token = localStorage.getItem('admin_token');
let tempToken = null; // 2FA 临时 token
let lastLoginAt = localStorage.getItem('admin_last_login'); // 最近登录时间
let currentPage = 'users';

// UTC时间转北京时间（UTC+8）
const toBeijingTime = (utcTimeStr) => {
  if (!utcTimeStr) return '-';
  const date = new Date(utcTimeStr);
  // 添加8小时转换为北京时间
  date.setHours(date.getHours() + 8);
  return date.toLocaleString('zh-CN', { 
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false 
  });
};

const api = async (url, options = {}) => {
  const headers = { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) };
  const res = await fetch(`${API_BASE}${url}`, { ...options, headers });
  if (res.status === 401) { logout(); throw new Error('未授权'); }
  return res.json();
};

const logout = () => { token = null; tempToken = null; lastLoginAt = null; localStorage.removeItem('admin_token'); localStorage.removeItem('admin_last_login'); render(); };

const render = () => {
  const app = document.getElementById('app');
  if (tempToken) { app.innerHTML = render2FA(); return; }
  if (!token) { app.innerHTML = renderLogin(); return; }
  let lastLoginText = '';
  if (lastLoginAt) {
    const date = new Date(lastLoginAt);
    date.setHours(date.getHours() + 8); // 增加8小时
    lastLoginText = `上次登录: ${date.toLocaleString()}`;
  }
  app.innerHTML = `
    <div class="sidebar d-flex flex-column">
      <div class="p-3 text-white"><h5>YouDu 管理后台</h5></div>
      <nav class="nav flex-column">
        <a class="nav-link ${currentPage === 'users' ? 'active' : ''}" href="#" onclick="showPage('users')"><i class="bi bi-people me-2"></i>用户管理</a>
        <a class="nav-link ${currentPage === 'messages' ? 'active' : ''}" href="#" onclick="showPage('messages')"><i class="bi bi-chat-dots me-2"></i>聊天记录</a>
        <a class="nav-link ${currentPage === 'inviteCodes' ? 'active' : ''}" href="#" onclick="showPage('inviteCodes')"><i class="bi bi-ticket me-2"></i>邀请码管理</a>
        <a class="nav-link ${currentPage === 'admins' ? 'active' : ''}" href="#" onclick="showPage('admins')"><i class="bi bi-person-gear me-2"></i>账号管理</a>
        <a class="nav-link" href="#" onclick="logout()"><i class="bi bi-box-arrow-right me-2"></i>退出登录</a>
      </nav>
      <div class="mt-auto p-3 text-light small" style="opacity:0.7">${lastLoginText || '首次登录'}</div>
    </div>
    <div class="main-content"><div id="page-content"></div></div>`;
  loadPage();
};

const showPage = (page) => { currentPage = page; loadPage(); document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active')); event.target.classList.add('active'); };

const loadPage = () => {
  const content = document.getElementById('page-content');
  if (currentPage === 'users') loadUsers(content);
  else if (currentPage === 'messages') loadMessages(content);
  else if (currentPage === 'inviteCodes') loadInviteCodes(content);
  else if (currentPage === 'admins') loadAdmins(content);
};

const renderLogin = () => `
  <div class="login-container">
    <div class="card p-4">
      <h4 class="text-center mb-4">有度管理系统</h4>
      <form onsubmit="handleLogin(event)" autocomplete="off">
        <div class="mb-3"><input type="text" class="form-control" id="username" placeholder="用户名" required autocomplete="new-password"></div>
        <div class="mb-3"><input type="password" class="form-control" id="password" placeholder="密码" required autocomplete="new-password"></div>
        <button type="submit" class="btn btn-primary w-100">登录</button>
      </form>
    </div>
  </div>`;

const render2FA = () => `
  <div class="login-container">
    <div class="card p-4">
      <h4 class="text-center mb-4">两步验证</h4>
      <p class="text-center text-muted mb-3">请输入 Google Authenticator 中的 6 位验证码</p>
      <form onsubmit="handle2FA(event)" autocomplete="off">
        <div class="mb-3">
          <input type="text" class="form-control text-center" id="totpCode" placeholder="000000" 
            maxlength="6" pattern="[0-9]{6}" required autocomplete="off"
            style="font-size: 24px; letter-spacing: 8px;">
        </div>
        <button type="submit" class="btn btn-primary w-100">验证</button>
        <button type="button" class="btn btn-link w-100 mt-2" onclick="cancelLogin()">返回登录</button>
      </form>
    </div>
  </div>`;

const handleLogin = async (e) => {
  e.preventDefault();
  try {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: document.getElementById('username').value,
        password: document.getElementById('password').value
      })
    }).then(r => r.json());
    
    if (res.error) {
      alert(res.error);
      return;
    }
    
    if (res.require2FA) {
      tempToken = res.tempToken;
      render();
    } else {
      token = res.token;
      localStorage.setItem('admin_token', token);
      render();
    }
  } catch { alert('登录失败'); }
};

const handle2FA = async (e) => {
  e.preventDefault();
  try {
    const res = await fetch(`${API_BASE}/auth/verify-2fa`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tempToken: tempToken,
        code: document.getElementById('totpCode').value
      })
    }).then(r => r.json());
    
    if (res.error) {
      alert(res.error);
      return;
    }
    
    token = res.token;
    tempToken = null;
    lastLoginAt = res.lastLoginAt;
    localStorage.setItem('admin_token', token);
    if (lastLoginAt) localStorage.setItem('admin_last_login', lastLoginAt);
    render();
  } catch { alert('验证失败'); }
};

const cancelLogin = () => {
  tempToken = null;
  render();
};


// 用户管理
let userPage = 1, userUsername = '', userFullName = '', userEmail = '', userStatus = '', userPageSize = 10;
const loadUsers = async (container) => {
  const params = new URLSearchParams({ 
    page: userPage, 
    limit: userPageSize, 
    ...(userUsername && { username: userUsername }),
    ...(userFullName && { full_name: userFullName }),
    ...(userEmail && { email: userEmail }),
    ...(userStatus && { status: userStatus }) 
  });
  const res = await api(`/users?${params}`);
  container.innerHTML = `
    <div class="card">
      <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">用户管理</h5>
        <button class="btn btn-primary btn-sm" onclick="showAddUserModal()"><i class="bi bi-plus"></i> 新增用户</button>
      </div>
      <div class="card-body">
        <div class="row mb-3 g-2">
          <div class="col-md-2"><input type="text" class="form-control" placeholder="用户名" value="${userUsername}" onchange="userUsername=this.value;userPage=1;loadPage()"></div>
          <div class="col-md-2"><input type="text" class="form-control" placeholder="姓名" value="${userFullName}" onchange="userFullName=this.value;userPage=1;loadPage()"></div>
          <div class="col-md-2"><input type="text" class="form-control" placeholder="邮箱" value="${userEmail}" onchange="userEmail=this.value;userPage=1;loadPage()"></div>
          <div class="col-md-2">
            <select class="form-select" onchange="userStatus=this.value;userPage=1;loadPage()">
              <option value="">全部状态</option>
              <option value="online" ${userStatus==='online'?'selected':''}>在线</option>
              <option value="offline" ${userStatus==='offline'?'selected':''}>离线</option>
              <option value="disabled" ${userStatus==='disabled'?'selected':''}>已禁用</option>
            </select>
          </div>
          <div class="col-md-2"><button class="btn btn-outline-secondary w-100" onclick="userUsername='';userFullName='';userEmail='';userStatus='';userPage=1;loadPage()">重置</button></div>
        </div>
        <table class="table table-hover">
          <thead><tr><th style="width:50px">ID</th><th style="width:100px">用户名</th><th style="width:100px">姓名</th><th style="width:160px">邮箱</th><th style="width:80px">部门</th><th style="width:120px">备注</th><th style="width:60px">状态</th><th style="width:140px">注册时间</th><th style="width:140px">最近登录</th><th style="width:160px">操作</th></tr></thead>
          <tbody>${res.data.map(u => `
            <tr>
              <td>${u.id}</td><td>${u.username}</td><td style="max-width:100px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${u.full_name || ''}">${u.full_name || '-'}</td><td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${u.email || ''}">${u.email || '-'}</td><td style="max-width:80px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${u.department || '-'}</td>
              <td style="max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${u.remark || ''}">${u.remark || '-'}</td>
              <td><span class="badge ${u.status==='disabled'?'bg-danger':u.status==='online'?'bg-success':'bg-secondary'}">${u.status==='disabled'?'已禁用':u.status==='online'?'在线':'离线'}</span></td>
              <td>${toBeijingTime(u.created_at)}</td>
              <td>${toBeijingTime(u.last_login_at)}</td>
              <td>
                <button class="btn btn-sm btn-outline-primary" onclick="showUserDetail(${u.id})"><i class="bi bi-eye"></i></button>
                <button class="btn btn-sm btn-outline-warning" onclick="showEditUserModal(${u.id})"><i class="bi bi-pencil"></i></button>
                <button class="btn btn-sm btn-outline-${u.status==='disabled'?'success':'secondary'}" onclick="toggleUserStatus(${u.id},'${u.status}')">${u.status==='disabled'?'启用':'禁用'}</button>
                <button class="btn btn-sm btn-outline-danger" onclick="deleteUser(${u.id})"><i class="bi bi-trash"></i></button>
              </td>
            </tr>`).join('')}</tbody>
        </table>
        ${renderPagination(res, 'userPage', 'loadPage', 'userPageSize')}
      </div>
    </div>
    <div class="modal fade" id="userModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h5 class="modal-title" id="userModalTitle">用户</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body" id="userModalBody"></div></div></div></div>`;
};

const showAddUserModal = () => {
  document.getElementById('userModalTitle').textContent = '新增用户';
  document.getElementById('userModalBody').innerHTML = `
    <form onsubmit="addUser(event)">
      <div class="mb-3"><label class="form-label">用户名 *</label><input type="text" class="form-control" id="newUsername" required></div>
      <div class="mb-3"><label class="form-label">密码 *</label><input type="password" class="form-control" id="newPassword" required></div>
      <div class="mb-3"><label class="form-label">姓名 *</label><input type="text" class="form-control" id="newFullName" required></div>
      <div class="mb-3"><label class="form-label">手机</label><input type="text" class="form-control" id="newPhone"></div>
      <div class="mb-3"><label class="form-label">邮箱</label><input type="email" class="form-control" id="newEmail"></div>
      <div class="mb-3"><label class="form-label">部门</label><input type="text" class="form-control" id="newDepartment"></div>
      <div class="mb-3"><label class="form-label">备注</label><textarea class="form-control" id="newRemark" rows="2"></textarea></div>
      <button type="submit" class="btn btn-primary">创建</button>
    </form>`;
  new bootstrap.Modal(document.getElementById('userModal')).show();
};

const addUser = async (e) => {
  e.preventDefault();
  await api('/users', { method: 'POST', body: JSON.stringify({ username: document.getElementById('newUsername').value, password: document.getElementById('newPassword').value, full_name: document.getElementById('newFullName').value, phone: document.getElementById('newPhone').value, email: document.getElementById('newEmail').value, department: document.getElementById('newDepartment').value, remark: document.getElementById('newRemark').value }) });
  bootstrap.Modal.getInstance(document.getElementById('userModal')).hide();
  loadPage();
};

const showUserDetail = async (id) => {
  const user = await api(`/users/${id}`);
  document.getElementById('userModalTitle').textContent = '用户详情';
  document.getElementById('userModalBody').innerHTML = `
    <table class="table"><tbody>
      <tr><th>ID</th><td>${user.id}</td></tr>
      <tr><th>用户名</th><td>${user.username}</td></tr>
      <tr><th>姓名</th><td>${user.full_name || '-'}</td></tr>
      <tr><th>手机</th><td>${user.phone || '-'}</td></tr>
      <tr><th>邮箱</th><td>${user.email || '-'}</td></tr>
      <tr><th>性别</th><td>${user.gender || '-'}</td></tr>
      <tr><th>部门</th><td>${user.department || '-'}</td></tr>
      <tr><th>职位</th><td>${user.position || '-'}</td></tr>
      <tr><th>地区</th><td>${user.region || '-'}</td></tr>
      <tr><th>邀请码</th><td>${user.invite_code || '-'}</td></tr>
      <tr><th>备注</th><td>${user.remark || '-'}</td></tr>
      <tr><th>状态</th><td>${user.status}</td></tr>
      <tr><th>注册时间</th><td>${toBeijingTime(user.created_at)}</td></tr>
      <tr><th>最近登录</th><td>${toBeijingTime(user.last_login_at)}</td></tr>
    </tbody></table>`;
  new bootstrap.Modal(document.getElementById('userModal')).show();
};

const showEditUserModal = async (id) => {
  const user = await api(`/users/${id}`);
  document.getElementById('userModalTitle').textContent = '编辑用户';
  document.getElementById('userModalBody').innerHTML = `
    <form onsubmit="updateUser(event, ${id})">
      <div class="mb-3"><label class="form-label">姓名</label><input type="text" class="form-control" id="editFullName" value="${user.full_name || ''}"></div>
      <div class="mb-3"><label class="form-label">手机</label><input type="text" class="form-control" id="editPhone" value="${user.phone || ''}"></div>
      <div class="mb-3"><label class="form-label">邮箱</label><input type="email" class="form-control" id="editEmail" value="${user.email || ''}"></div>
      <div class="mb-3"><label class="form-label">部门</label><input type="text" class="form-control" id="editDepartment" value="${user.department || ''}"></div>
      <div class="mb-3"><label class="form-label">职位</label><input type="text" class="form-control" id="editPosition" value="${user.position || ''}"></div>
      <div class="mb-3"><label class="form-label">备注</label><textarea class="form-control" id="editRemark" rows="2">${user.remark || ''}</textarea></div>
      <button type="submit" class="btn btn-primary">保存</button>
    </form>`;
  new bootstrap.Modal(document.getElementById('userModal')).show();
};

const updateUser = async (e, id) => {
  e.preventDefault();
  await api(`/users/${id}`, { method: 'PUT', body: JSON.stringify({ full_name: document.getElementById('editFullName').value, phone: document.getElementById('editPhone').value, email: document.getElementById('editEmail').value, department: document.getElementById('editDepartment').value, position: document.getElementById('editPosition').value, remark: document.getElementById('editRemark').value }) });
  bootstrap.Modal.getInstance(document.getElementById('userModal')).hide();
  loadPage();
};

const toggleUserStatus = async (id, currentStatus) => {
  const newStatus = currentStatus === 'disabled' ? 'offline' : 'disabled';
  await api(`/users/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status: newStatus }) });
  loadPage();
};

const deleteUser = async (id) => {
  if (!confirm('确定要删除此用户吗？')) return;
  await api(`/users/${id}`, { method: 'DELETE' });
  loadPage();
};


// 聊天记录
let msgPage = 1, selectedChat = null;
let msgFilter = { chatType: '', senderId: '', receiverId: '', groupId: '', startDate: '', endDate: '' };
let allUsers = [], allGroups = [];

const loadFilterOptions = async () => {
  if (allUsers.length === 0) {
    const usersRes = await api('/messages/users');
    allUsers = usersRes.data || [];
  }
  if (allGroups.length === 0) {
    const groupsRes = await api('/messages/groups');
    allGroups = groupsRes.data || [];
  }
};

const getSelectedUserName = (userId, users) => {
  if (!userId) return '';
  const user = users.find(u => u.id == userId);
  return user ? `${user.username}${user.full_name ? ' (' + user.full_name + ')' : ''}` : '';
};

const getSelectedGroupName = (groupId, groups) => {
  if (!groupId) return '';
  const group = groups.find(g => g.id == groupId);
  return group ? group.name : '';
};

const loadMessages = async (container) => {
  await loadFilterOptions();
  
  const params = new URLSearchParams({ page: msgPage, limit: 20 });
  if (msgFilter.chatType) params.append('chat_type', msgFilter.chatType);
  if (msgFilter.senderId) params.append('sender_id', msgFilter.senderId);
  if (msgFilter.receiverId) params.append('receiver_id', msgFilter.receiverId);
  if (msgFilter.groupId) params.append('group_id', msgFilter.groupId);
  if (msgFilter.startDate) params.append('start_date', msgFilter.startDate);
  if (msgFilter.endDate) params.append('end_date', msgFilter.endDate);
  
  const res = await api(`/messages/conversations?${params}`);
  
  const userDatalistOptions = allUsers.map(u => `<option value="${u.username}${u.full_name ? ' (' + u.full_name + ')' : ''}" data-id="${u.id}"></option>`).join('');
  const groupDatalistOptions = allGroups.map(g => `<option value="${g.name}" data-id="${g.id}"></option>`).join('');
  
  container.innerHTML = `
    <div class="messages-page">
      <div class="row">
        <div class="col-md-4">
          <div class="card">
            <div class="card-header"><h5 class="mb-0">会话列表</h5></div>
            <div class="card-body filter-area">
              <div class="row g-2 mb-2">
                <div class="col-6">
                  <input type="text" class="form-control form-control-sm" list="senderList" placeholder="搜索发送人" 
                    value="${getSelectedUserName(msgFilter.senderId, allUsers)}" 
                    onchange="handleUserSelect(this, 'sender')" autocomplete="off">
                  <datalist id="senderList">${userDatalistOptions}</datalist>
                </div>
                <div class="col-6">
                  <input type="text" class="form-control form-control-sm" list="receiverList" placeholder="搜索接收人" 
                    value="${getSelectedUserName(msgFilter.receiverId, allUsers)}" 
                    onchange="handleUserSelect(this, 'receiver')" autocomplete="off"
                    ${msgFilter.chatType === 'group' ? 'disabled' : ''}>
                  <datalist id="receiverList">${userDatalistOptions}</datalist>
                </div>
              </div>
              <div class="row g-2 mb-2">
                <div class="col-6">
                  <select class="form-select form-select-sm" onchange="handleChatTypeChange(this.value)">
                    <option value="">全部类型</option>
                    <option value="private" ${msgFilter.chatType === 'private' ? 'selected' : ''}>单聊</option>
                    <option value="group" ${msgFilter.chatType === 'group' ? 'selected' : ''}>群聊</option>
                  </select>
                </div>
                <div class="col-6" id="groupSelectWrapper" style="${msgFilter.chatType === 'group' ? '' : 'display:none'}">
                  <input type="text" class="form-control form-control-sm" list="groupList" placeholder="搜索群组" 
                    value="${getSelectedGroupName(msgFilter.groupId, allGroups)}" 
                    onchange="handleGroupSelect(this)" autocomplete="off">
                  <datalist id="groupList">${groupDatalistOptions}</datalist>
                </div>
              </div>
              <div class="row g-2 mb-2">
                <div class="col-6">
                  <input type="datetime-local" class="form-control form-control-sm" placeholder="开始时间" value="${msgFilter.startDate}" onchange="msgFilter.startDate=this.value">
                </div>
                <div class="col-6">
                  <input type="datetime-local" class="form-control form-control-sm" placeholder="结束时间" value="${msgFilter.endDate}" onchange="msgFilter.endDate=this.value">
                </div>
              </div>
              <div class="mb-2 text-center">
                <button class="btn btn-sm btn-outline-secondary me-2" onclick="resetMsgFilter()">重置筛选</button>
                <button class="btn btn-sm btn-primary" onclick="msgPage=1;loadPage()">查询</button>
              </div>
            </div>
            <div class="list-group list-group-flush">
              ${res.data.map(c => {
                const isGroup = c.chat_type === 'group';
                const displayName = isGroup ? `[群] ${c.group_name}` : `${c.sender_name} ↔ ${c.receiver_name}`;
                const isSelected = selectedChat && (
                (isGroup && selectedChat.isGroup && selectedChat.groupId === c.group_id) ||
                (!isGroup && !selectedChat.isGroup && selectedChat.user1 === Math.min(c.sender_id, c.receiver_id) && selectedChat.user2 === Math.max(c.sender_id, c.receiver_id))
              );
              return `
              <a href="#" class="list-group-item list-group-item-action ${isSelected ? 'active' : ''}" 
                 onclick="selectChat(${c.sender_id}, ${c.receiver_id || 0}, '${c.sender_name}', '${c.receiver_name || ''}', ${isGroup}, ${c.group_id || 0}, '${c.group_name || ''}')">
                <div class="d-flex justify-content-between"><strong>${displayName}</strong><small>${new Date(c.created_at).toLocaleDateString()}</small></div>
                <small class="text-muted">${c.content.substring(0, 30)}${c.content.length > 30 ? '...' : ''}</small>
              </a>`;
            }).join('')}
            </div>
            ${renderPagination(res, 'msgPage', 'loadPage')}
          </div>
        </div>
        <div class="col-md-8"><div id="chatDetail">${selectedChat ? '' : '<div class="card h-100"><div class="card-body text-center text-muted d-flex align-items-center justify-content-center">选择一个会话查看聊天记录</div></div>'}</div></div>
      </div>
    </div>`;
  if (selectedChat) loadChatDetail();
};

const handleChatTypeChange = (value) => {
  msgFilter.chatType = value;
  if (value === 'group') {
    msgFilter.receiverId = '';
  } else {
    msgFilter.groupId = '';
  }
  msgPage = 1;
  loadPage();
};

const handleUserSelect = (input, type) => {
  const value = input.value;
  const user = allUsers.find(u => `${u.username}${u.full_name ? ' (' + u.full_name + ')' : ''}` === value);
  if (type === 'sender') {
    msgFilter.senderId = user ? user.id : '';
  } else {
    msgFilter.receiverId = user ? user.id : '';
  }
  if (!value) {
    if (type === 'sender') msgFilter.senderId = '';
    else msgFilter.receiverId = '';
  }
  msgPage = 1;
  loadPage();
};

const handleGroupSelect = (input) => {
  const value = input.value;
  const group = allGroups.find(g => g.name === value);
  msgFilter.groupId = group ? group.id : '';
  if (!value) msgFilter.groupId = '';
  msgPage = 1;
  loadPage();
};

const resetMsgFilter = () => {
  msgFilter = { chatType: '', senderId: '', receiverId: '', groupId: '', startDate: '', endDate: '' };
  msgPage = 1;
  loadPage();
};

const selectChat = (user1, user2, name1, name2, isGroup, groupId, groupName) => {
  if (isGroup) {
    selectedChat = { isGroup: true, groupId, groupName };
  } else {
    selectedChat = { isGroup: false, user1: Math.min(user1, user2), user2: Math.max(user1, user2), name1, name2 };
  }
  loadPage();
};

let chatPage = 1;
const loadChatDetail = async () => {
  let res, title;
  
  if (selectedChat.isGroup) {
    // 群聊消息
    res = await api(`/messages/group/${selectedChat.groupId}?page=${chatPage}&limit=50`);
    title = `[群] ${selectedChat.groupName}`;
  } else {
    // 私聊消息
    res = await api(`/messages/chat/${selectedChat.user1}/${selectedChat.user2}?page=${chatPage}&limit=50`);
    title = `${selectedChat.name1} ↔ ${selectedChat.name2}`;
  }
  
  document.getElementById('chatDetail').innerHTML = `
    <div class="card h-100">
      <div class="card-header"><h5 class="mb-0">${title}</h5></div>
      <div class="card-body chat-container">
        ${res.data.map(m => {
          const isLeft = selectedChat.isGroup ? true : m.sender_id === selectedChat.user1;
          return `
          <div class="d-flex ${isLeft ? '' : 'flex-row-reverse'}">
            <div class="chat-message ${isLeft ? 'received' : 'sent'}">
              <small class="d-block ${isLeft ? '' : 'text-end'}">${m.sender_name} · ${new Date(m.created_at).toLocaleString()}</small>
              ${m.status === 'recalled' ? '<em class="text-muted">消息已撤回</em>' : renderMessageContent(m)}
            </div>
          </div>`;
        }).join('')}
      </div>
      <div class="card-footer">${renderPagination(res, 'chatPage', 'loadChatDetail')}</div>
    </div>`;
};

const renderMessageContent = (m) => {
  if (m.message_type === 'image') return `<img src="${m.content}" style="max-width:200px;max-height:200px" class="rounded">`;
  if (m.message_type === 'file') return `<a href="${m.content}" target="_blank"><i class="bi bi-file-earmark"></i> ${m.file_name || '文件'}</a>`;
  if (m.message_type === 'voice') return `<i class="bi bi-mic"></i> 语音消息 ${m.voice_duration ? `(${m.voice_duration}秒)` : ''}`;
  return m.content;
};


// 邀请码管理
let codePage = 1, codeStatus = '', codePageSize = 10, codeCode = '', codeUsername = '', codeFullname = '', codeEmail = '';
const loadInviteCodes = async (container) => {
  const params = new URLSearchParams({
    page: codePage,
    limit: codePageSize,
    ...(codeStatus && { status: codeStatus }),
    ...(codeCode && { code: codeCode }),
    ...(codeUsername && { username: codeUsername }),
    ...(codeFullname && { fullname: codeFullname }),
    ...(codeEmail && { email: codeEmail })
  });
  const [res, stats] = await Promise.all([
    api(`/invite-codes?${params}`),
    api('/invite-codes/stats')
  ]);
  container.innerHTML = `
    <div class="card">
      <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">邀请码管理</h5>
        <div>
          <span class="badge bg-info me-2">总计: ${stats.total}</span>
          <span class="badge bg-success me-2">未使用: ${stats.unused}</span>
          <span class="badge bg-secondary me-2">已使用: ${stats.used}</span>
          <button class="btn btn-primary btn-sm" onclick="showGenerateModal()"><i class="bi bi-plus"></i> 生成邀请码</button>
        </div>
      </div>
      <div class="card-body">
        <div class="row mb-3 g-2">
          <div class="col-md-2"><input type="text" class="form-control" placeholder="邀请码" value="${codeCode}" onchange="codeCode=this.value;codePage=1;loadPage()"></div>
          <div class="col-md-2"><input type="text" class="form-control" placeholder="绑定用户" value="${codeUsername}" onchange="codeUsername=this.value;codePage=1;loadPage()"></div>
          <div class="col-md-2"><input type="text" class="form-control" placeholder="绑定昵称" value="${codeFullname}" onchange="codeFullname=this.value;codePage=1;loadPage()"></div>
          <div class="col-md-2"><input type="text" class="form-control" placeholder="绑定邮箱" value="${codeEmail}" onchange="codeEmail=this.value;codePage=1;loadPage()"></div>
          <div class="col-md-2">
            <select class="form-select" onchange="codeStatus=this.value;codePage=1;loadPage()">
              <option value="">全部状态</option>
              <option value="unused" ${codeStatus==='unused'?'selected':''}>未使用</option>
              <option value="used" ${codeStatus==='used'?'selected':''}>已使用</option>
            </select>
          </div>
          <div class="col-md-2"><button class="btn btn-outline-secondary w-100" onclick="codeCode='';codeUsername='';codeFullname='';codeEmail='';codeStatus='';codePage=1;loadPage()">重置</button></div>
        </div>
        <table class="table table-hover">
          <thead><tr><th>ID</th><th>邀请码</th><th>总次数</th><th>已用</th><th>状态</th><th>绑定用户</th><th>绑定昵称</th><th>绑定邮箱</th><th>备注</th><th>创建时间</th><th>操作</th></tr></thead>
          <tbody>${res.data.map(c => {
            const isUsed = (c.total_count || 1) <= (c.used_count || 0);
            return `
            <tr>
              <td>${c.id}</td>
              <td><code>${c.code}</code> <i class="bi bi-copy text-muted" style="cursor:pointer;font-size:12px;opacity:0.6" onclick="copyToClipboard('${c.code}')" title="复制" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.6"></i></td>
              <td>${c.total_count || 1}</td>
              <td>${c.used_count || 0}</td>
              <td><span class="badge ${isUsed?'bg-secondary':'bg-success'}">${isUsed?'已使用':'未使用'}</span></td>
              <td>${c.used_by_username || '-'}</td>
              <td>${c.used_by_fullname || '-'}</td>
              <td>${c.used_by_email || '-'}</td>
              <td style="max-width:100px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${c.remark || ''}">${c.remark || '-'}</td>
              <td>${toBeijingTime(c.created_at)}</td>
              <td>
                <button class="btn btn-sm btn-outline-warning" onclick="showEditCodeModal(${c.id}, ${c.total_count || 1}, ${c.used_count || 0}, '${(c.remark || '').replace(/'/g, "\\'")}', '${c.code}')" title="编辑"><i class="bi bi-pencil"></i></button>
                <button class="btn btn-sm btn-outline-danger" onclick="deleteCode(${c.id})" title="删除"><i class="bi bi-trash"></i></button>
              </td>
            </tr>`;
          }).join('')}</tbody>
        </table>
        ${renderPagination(res, 'codePage', 'loadPage', 'codePageSize')}
      </div>
    </div>
    <div class="modal fade" id="generateModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
      <div class="modal-header"><h5 class="modal-title">生成邀请码</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
      <div class="modal-body">
        <form onsubmit="generateCodes(event)">
          <div class="mb-3"><label class="form-label">生成数量 (最多1000)</label><input type="number" class="form-control" id="generateCount" value="10" min="1" max="1000"></div>
          <div class="mb-3"><label class="form-label">每个邀请码可使用次数</label><input type="number" class="form-control" id="generateTotalCount" value="1" min="1" max="9999"></div>
          <button type="submit" class="btn btn-primary">生成</button>
        </form>
        <div id="generatedCodes" class="mt-3"></div>
      </div>
    </div></div></div>
    <div class="modal fade" id="editCodeModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
      <div class="modal-header"><h5 class="modal-title">编辑邀请码</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
      <div class="modal-body">
        <form onsubmit="updateCode(event)">
          <input type="hidden" id="editCodeId">
          <input type="hidden" id="editCodeUsedCount">
          <div class="mb-3"><label class="form-label">邀请码</label><input type="text" class="form-control" id="editCodeDisplay" readonly></div>
          <div class="mb-3"><label class="form-label">总次数 <small class="text-muted">(不能小于已使用次数: <span id="editCodeUsedCountDisplay">0</span>)</small></label><input type="number" class="form-control" id="editCodeTotalCount" min="1" max="9999" required></div>
          <div class="mb-3"><label class="form-label">备注</label><textarea class="form-control" id="editCodeRemark" rows="3" maxlength="500" placeholder="请输入备注信息（最多500字）"></textarea></div>
          <button type="submit" class="btn btn-primary">保存</button>
        </form>
      </div>
    </div></div></div>`;
};

const showGenerateModal = () => new bootstrap.Modal(document.getElementById('generateModal')).show();

const showEditCodeModal = (id, totalCount, usedCount, remark, code) => {
  document.getElementById('editCodeId').value = id;
  document.getElementById('editCodeUsedCount').value = usedCount;
  document.getElementById('editCodeDisplay').value = code;
  document.getElementById('editCodeTotalCount').value = totalCount;
  document.getElementById('editCodeTotalCount').min = usedCount || 1;
  document.getElementById('editCodeUsedCountDisplay').textContent = usedCount;
  document.getElementById('editCodeRemark').value = remark;
  new bootstrap.Modal(document.getElementById('editCodeModal')).show();
};

const updateCode = async (e) => {
  e.preventDefault();
  const id = document.getElementById('editCodeId').value;
  const totalCount = parseInt(document.getElementById('editCodeTotalCount').value);
  const usedCount = parseInt(document.getElementById('editCodeUsedCount').value);
  const remark = document.getElementById('editCodeRemark').value;
  
  if (totalCount < usedCount) {
    alert(`总次数不能小于已使用次数(${usedCount})`);
    return;
  }
  
  try {
    await api(`/invite-codes/${id}/total-count`, { method: 'PUT', body: JSON.stringify({ total_count: totalCount }) });
    await api(`/invite-codes/${id}/remark`, { method: 'PUT', body: JSON.stringify({ remark }) });
    bootstrap.Modal.getInstance(document.getElementById('editCodeModal')).hide();
    loadPage();
  } catch (err) {
    alert('保存失败: ' + err.message);
  }
};

const generateCodes = async (e) => {
  e.preventDefault();
  const count = document.getElementById('generateCount').value;
  const totalCount = document.getElementById('generateTotalCount').value;
  const res = await api('/invite-codes/generate', { method: 'POST', body: JSON.stringify({ count: parseInt(count), total_count: parseInt(totalCount) }) });
  document.getElementById('generatedCodes').innerHTML = `
    <div class="alert alert-success">${res.message}</div>
    <div class="border p-2" style="max-height:200px;overflow-y:auto"><code>${res.codes.join('<br>')}</code></div>
    <div class="mt-2">
      <button class="btn btn-sm btn-outline-primary me-2" onclick="copyToClipboard('${res.codes.join('\\n')}')">复制全部</button>
      <button class="btn btn-sm btn-secondary" onclick="closeGenerateModal()">关闭</button>
    </div>`;
};

const closeGenerateModal = () => {
  const modal = bootstrap.Modal.getInstance(document.getElementById('generateModal'));
  if (modal) modal.hide();
  document.getElementById('generatedCodes').innerHTML = '';
  loadPage();
};

const copyToClipboard = (text) => { navigator.clipboard.writeText(text); alert('已复制到剪贴板'); };

const deleteCode = async (id) => {
  if (!confirm('确定要删除此邀请码吗？')) return;
  await api(`/invite-codes/${id}`, { method: 'DELETE' });
  loadPage();
};

// 分页组件
const renderPagination = (res, pageVar, loadFunc, pageSizeVar = null) => {
  if (res.totalPages <= 1 && !pageSizeVar) return '';
  const pageSizeSelector = pageSizeVar ? `
    <select class="form-select form-select-sm" style="width:auto" onchange="${pageSizeVar}=parseInt(this.value);${pageVar}=1;${loadFunc}()">
      <option value="10" ${res.limit===10?'selected':''}>10条/页</option>
      <option value="20" ${res.limit===20?'selected':''}>20条/页</option>
      <option value="30" ${res.limit===30?'selected':''}>30条/页</option>
      <option value="50" ${res.limit===50?'selected':''}>50条/页</option>
      <option value="100" ${res.limit===100?'selected':''}>100条/页</option>
    </select>` : '';
  return `<nav class="d-flex justify-content-center align-items-center gap-3">
    ${pageSizeSelector}
    <ul class="pagination pagination-sm mb-0">
      <li class="page-item ${res.page <= 1 ? 'disabled' : ''}"><a class="page-link" href="#" onclick="${pageVar}=${res.page-1};${loadFunc}()">上一页</a></li>
      <li class="page-item disabled"><span class="page-link">${res.page} / ${res.totalPages}</span></li>
      <li class="page-item ${res.page >= res.totalPages ? 'disabled' : ''}"><a class="page-link" href="#" onclick="${pageVar}=${res.page+1};${loadFunc}()">下一页</a></li>
    </ul>
  </nav>`
};


// 账号管理
let adminPage = 1, adminPageSize = 10;
const loadAdmins = async (container) => {
  const params = new URLSearchParams({ page: adminPage, limit: adminPageSize });
  const res = await api(`/admins?${params}`);
  container.innerHTML = `
    <div class="card">
      <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">账号管理</h5>
        <button class="btn btn-primary btn-sm" onclick="showAddAdminModal()"><i class="bi bi-plus"></i> 添加管理员</button>
      </div>
      <div class="card-body">
        <table class="table table-hover">
          <thead><tr><th style="width:60px">ID</th><th>用户名</th><th>创建时间</th><th>最近登录</th><th style="width:150px">操作</th></tr></thead>
          <tbody>${res.data.map(a => `
            <tr>
              <td>${a.id}</td>
              <td>${a.username}</td>
              <td>${toBeijingTime(a.created_at)}</td>
              <td>${toBeijingTime(a.last_login_at)}</td>
              <td>
                <button class="btn btn-sm btn-outline-warning" onclick="showChangePasswordModal(${a.id}, '${a.username}')" title="修改密码"><i class="bi bi-key"></i></button>
                <button class="btn btn-sm btn-outline-danger" onclick="deleteAdmin(${a.id}, '${a.username}')" title="删除"><i class="bi bi-trash"></i></button>
              </td>
            </tr>`).join('')}</tbody>
        </table>
        ${renderPagination(res, 'adminPage', 'loadPage', 'adminPageSize')}
      </div>
    </div>
    <div class="modal fade" id="adminModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h5 class="modal-title" id="adminModalTitle">管理员</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body" id="adminModalBody"></div></div></div></div>`;
};

const showAddAdminModal = () => {
  document.getElementById('adminModalTitle').textContent = '添加管理员';
  document.getElementById('adminModalBody').innerHTML = `
    <form onsubmit="addAdmin(event)">
      <div class="mb-3"><label class="form-label">用户名 *</label><input type="text" class="form-control" id="newAdminUsername" required></div>
      <div class="mb-3"><label class="form-label">密码 *</label><input type="password" class="form-control" id="newAdminPassword" required minlength="6"></div>
      <div class="mb-3"><label class="form-label">确认密码 *</label><input type="password" class="form-control" id="newAdminConfirmPassword" required minlength="6"></div>
      <button type="submit" class="btn btn-primary">添加</button>
    </form>`;
  new bootstrap.Modal(document.getElementById('adminModal')).show();
};

const addAdmin = async (e) => {
  e.preventDefault();
  const password = document.getElementById('newAdminPassword').value;
  const confirmPassword = document.getElementById('newAdminConfirmPassword').value;
  if (password !== confirmPassword) {
    alert('两次输入的密码不一致');
    return;
  }
  try {
    const res = await api('/admins', { 
      method: 'POST', 
      body: JSON.stringify({ 
        username: document.getElementById('newAdminUsername').value, 
        password: password 
      }) 
    });
    if (res.error) {
      alert(res.error);
      return;
    }
    bootstrap.Modal.getInstance(document.getElementById('adminModal')).hide();
    loadPage();
  } catch (err) {
    alert('添加失败');
  }
};

const showChangePasswordModal = (id, username) => {
  document.getElementById('adminModalTitle').textContent = `修改密码 - ${username}`;
  document.getElementById('adminModalBody').innerHTML = `
    <form onsubmit="changeAdminPassword(event, ${id})">
      <div class="mb-3"><label class="form-label">新密码 *</label><input type="password" class="form-control" id="newPassword" required minlength="6"></div>
      <div class="mb-3"><label class="form-label">确认密码 *</label><input type="password" class="form-control" id="confirmNewPassword" required minlength="6"></div>
      <button type="submit" class="btn btn-primary">修改</button>
    </form>`;
  new bootstrap.Modal(document.getElementById('adminModal')).show();
};

const changeAdminPassword = async (e, id) => {
  e.preventDefault();
  const password = document.getElementById('newPassword').value;
  const confirmPassword = document.getElementById('confirmNewPassword').value;
  if (password !== confirmPassword) {
    alert('两次输入的密码不一致');
    return;
  }
  try {
    const res = await api(`/admins/${id}/password`, { 
      method: 'PUT', 
      body: JSON.stringify({ password }) 
    });
    if (res.error) {
      alert(res.error);
      return;
    }
    bootstrap.Modal.getInstance(document.getElementById('adminModal')).hide();
    alert('密码修改成功');
  } catch (err) {
    alert('修改失败');
  }
};

const deleteAdmin = async (id, username) => {
  if (!confirm(`确定要删除管理员 "${username}" 吗？`)) return;
  try {
    const res = await api(`/admins/${id}`, { method: 'DELETE' });
    if (res.error) {
      alert(res.error);
      return;
    }
    loadPage();
  } catch (err) {
    alert('删除失败');
  }
};

// 初始化
render();
