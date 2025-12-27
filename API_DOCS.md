# CollabU 后端 API 文档

> **Base URL**: `http://<host>:<port>/api`  
> **Authentication**: JWT Bearer Token (除注册和登录外，所有接口需在 Header 中携带 `Authorization: Bearer <token>`)

---

## 目录

1. [认证模块 (Auth)](#1-认证模块-auth)
2. [团队模块 (Teams)](#2-团队模块-teams)
3. [项目模块 (Projects)](#3-项目模块-projects)
4. [任务模块 (Tasks)](#4-任务模块-tasks)
5. [文件模块 (Files)](#5-文件模块-files)
6. [通知模块 (Notifications)](#6-通知模块-notifications)
7. [资源模块 (Resources)](#7-资源模块-resources)
8. [时间轴模块 (Timeline)](#8-时间轴模块-timeline)
9. [学习进度模块 (Learning)](#9-学习进度模块-learning)
10. [仪表盘模块 (Dashboard)](#10-仪表盘模块-dashboard)
11. [WebSocket 事件](#11-websocket-事件)

---

## 1. 认证模块 (Auth)

**前缀**: `/api/auth`

### 1.1 用户注册

```
POST /api/auth/register
```

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | ✅ | 用户名 (唯一) |
| email | string | ✅ | 邮箱 (唯一) |
| password | string | ✅ | 密码 |
| student_id | string | ❌ | 学号 |
| nickname | string | ❌ | 昵称 |

**响应**:
- `201 Created`
```json
{ "message": "User registered successfully" }
```

- `400 Bad Request`
```json
{ "message": "Missing required fields" }
{ "message": "Username already exists" }
{ "message": "Email already exists" }
```

---

### 1.2 用户登录

```
POST /api/auth/login
```

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | ✅ | 用户名或邮箱 |
| password | string | ✅ | 密码 |

**响应**:
- `200 OK`
```json
{
  "access_token": "<JWT_TOKEN>",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "student_id": "2021001",
    "nickname": "Test"
  }
}
```

- `401 Unauthorized`
```json
{ "message": "Invalid credentials" }
```

---

### 1.3 获取当前用户信息

```
GET /api/auth/me
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "student_id": "2021001",
  "nickname": "Test",
  "avatar": "/uploads/avatar.jpg"
}
```

---

### 1.4 更新用户资料

```
PUT /api/auth/profile
```
🔒 **需要认证**

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| nickname | string | ❌ | 新昵称 |

**响应**:
- `200 OK`
```json
{ "message": "Profile updated successfully" }
```

---

### 1.5 修改密码

```
PUT /api/auth/password
```
🔒 **需要认证**

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| old_password | string | ✅ | 原密码 |
| new_password | string | ✅ | 新密码 |

**响应**:
- `200 OK`
```json
{ "message": "Password updated successfully" }
```

- `400 Bad Request`
```json
{ "message": "Invalid old password" }
```

---

## 2. 团队模块 (Teams)

**前缀**: `/api/teams`

### 2.1 获取用户所属团队列表

```
GET /api/teams
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "name": "Team Alpha",
    "description": "项目团队",
    "avatar": "/uploads/team_avatar.jpg",
    "creator_id": 1,
    "created_at": "2024-01-01T00:00:00"
  }
]
```

---

### 2.2 创建团队

```
POST /api/teams
```
🔒 **需要认证**

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ✅ | 团队名称 |
| description | string | ❌ | 团队描述 |

**响应**:
- `201 Created`
```json
{
  "id": 1,
  "name": "Team Alpha",
  "invite_code": "a1b2c3d4",
  "message": "Team created successfully"
}
```

---

### 2.3 获取团队详情

```
GET /api/teams/{id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{
  "id": 1,
  "name": "Team Alpha",
  "description": "项目团队",
  "avatar": "/uploads/team_avatar.jpg",
  "invite_code": "a1b2c3d4",
  "creator_id": 1,
  "created_at": "2024-01-01T00:00:00"
}
```

---

### 2.4 更新团队信息

```
PUT /api/teams/{id}
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ❌ | 团队名称 |
| description | string | ❌ | 团队描述 |
| avatar | string | ❌ | 头像URL |

**响应**:
- `200 OK`
```json
{ "message": "Team updated successfully" }
```

---

### 2.5 解散团队

```
DELETE /api/teams/{id}
```
🔒 **需要认证**（仅创建者）

**响应**:
- `200 OK`
```json
{ "message": "Team dissolved successfully" }
```

- `403 Forbidden`
```json
{ "message": "Only creator can dissolve team" }
```

---

### 2.6 获取团队成员列表

```
GET /api/teams/{id}/members
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "user_id": 1,
    "username": "user1",
    "nickname": "User One",
    "avatar": "/uploads/avatar.jpg",
    "role": "creator",
    "joined_at": "2024-01-01T00:00:00"
  }
]
```

---

### 2.7 生成新邀请码

```
POST /api/teams/{id}/invite
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{ "invite_code": "x1y2z3w4" }
```

---

### 2.8 通过邀请码加入团队

```
POST /api/teams/join
```
🔒 **需要认证**

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| invite_code | string | ✅ | 邀请码 |

**响应**:
- `200 OK`
```json
{ "message": "Joined team successfully", "team_id": 1 }
```

- `404 Not Found`
```json
{ "message": "Invalid invite code" }
```

---

### 2.9 离开团队

```
POST /api/teams/{id}/leave
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{ "message": "Left team successfully" }
```

- `400 Bad Request`
```json
{ "message": "Creator cannot leave team. Dissolve it instead." }
```

---

### 2.10 获取团队聊天消息

```
GET /api/teams/{id}/messages
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "user_id": 1,
    "username": "user1",
    "nickname": "User One",
    "avatar": "/uploads/avatar.jpg",
    "content": "Hello team!",
    "created_at": "2024-01-01T12:00:00"
  }
]
```

---

### 2.11 获取团队日历任务

```
GET /api/teams/{id}/tasks
```
🔒 **需要认证**（需为团队成员）

**说明**: 返回团队所有项目中带有日期的任务（用于日历视图）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "title": "完成设计稿",
    "project_id": 1,
    "start_date": "2024-01-15",
    "end_date": "2024-01-20",
    "status": "in_progress",
    "priority": "high"
  }
]
```

---

## 3. 项目模块 (Projects)

**前缀**: `/api/projects`

### 3.1 获取项目列表

```
GET /api/projects?team_id={team_id}
```
🔒 **需要认证**

**参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| team_id | integer | ✅ | 团队ID |

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "name": "Project Alpha",
    "description": "第一个项目",
    "status": "active",
    "start_date": "2024-01-01",
    "end_date": "2024-06-30",
    "created_by": 1,
    "created_at": "2024-01-01T00:00:00"
  }
]
```

---

### 3.2 创建项目

```
POST /api/projects
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| team_id | integer | ✅ | 团队ID |
| name | string | ✅ | 项目名称 |
| description | string | ❌ | 项目描述 |
| start_date | string | ❌ | 开始日期 (YYYY-MM-DD) |
| end_date | string | ❌ | 结束日期 (YYYY-MM-DD) |

**响应**:
- `201 Created`
```json
{ "message": "Project created successfully", "id": 1 }
```

---

### 3.3 获取项目详情

```
GET /api/projects/{id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{
  "id": 1,
  "team_id": 1,
  "name": "Project Alpha",
  "description": "第一个项目",
  "status": "active",
  "start_date": "2024-01-01",
  "end_date": "2024-06-30",
  "created_by": 1,
  "created_at": "2024-01-01T00:00:00"
}
```

---

### 3.4 更新项目

```
PUT /api/projects/{id}
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ❌ | 项目名称 |
| description | string | ❌ | 项目描述 |
| status | string | ❌ | 状态 |
| start_date | string | ❌ | 开始日期 |
| end_date | string | ❌ | 结束日期 |

**响应**:
- `200 OK`
```json
{ "message": "Project updated successfully" }
```

---

### 3.5 删除项目

```
DELETE /api/projects/{id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{ "message": "Project deleted successfully" }
```

---

## 4. 任务模块 (Tasks)

**前缀**: `/api/tasks`

### 4.1 获取任务列表

```
GET /api/tasks?project_id={project_id}&parent_id={parent_id}&fetch_all={fetch_all}
```
🔒 **需要认证**（需为团队成员）

**参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| project_id | integer | ✅ | 项目ID |
| parent_id | integer | ❌ | 父任务ID（不填则获取根任务） |
| fetch_all | string | ❌ | 设为 "true" 获取所有任务 |

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "parent_id": null,
    "title": "任务1",
    "description": "任务描述",
    "status": "pending",
    "priority": "high",
    "progress": 0,
    "start_date": "2024-01-15",
    "end_date": "2024-01-20",
    "participants": [
      { "id": 1, "username": "user1", "nickname": "User", "avatar": null }
    ],
    "has_subtasks": true,
    "level": 0
  }
]
```

---

### 4.2 获取甘特图数据

```
GET /api/tasks/gantt-data?project_id={project_id}
```
🔒 **需要认证**（需为团队成员）

**说明**: 返回 dhtmlx-gantt 兼容格式的任务和链接数据

**响应**:
- `200 OK`
```json
{
  "data": [
    {
      "id": 1,
      "text": "任务1",
      "start_date": "2024-01-15",
      "duration": 5,
      "parent": 0,
      "progress": 0.5,
      "open": true
    }
  ],
  "links": [
    { "id": 1, "source": 1, "target": 2, "type": "0" }
  ]
}
```

---

### 4.3 创建任务

```
POST /api/tasks
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| project_id | integer | ✅ | 项目ID |
| title | string | ✅ | 任务标题 |
| parent_id | integer | ❌ | 父任务ID（子任务时需要） |
| description | string | ❌ | 任务描述 |
| priority | string | ❌ | 优先级：high/medium/low，默认 medium |
| start_date | string | ❌ | 开始日期 (YYYY-MM-DD) |
| end_date | string | ❌ | 结束日期 (YYYY-MM-DD) |

**响应**:
- `201 Created`
```json
{ "message": "Task created successfully", "id": 1 }
```

---

### 4.4 获取任务详情

```
GET /api/tasks/{id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{
  "id": 1,
  "project_id": 1,
  "parent_id": null,
  "title": "任务1",
  "description": "任务描述",
  "status": "pending",
  "priority": "high",
  "progress": 50,
  "start_date": "2024-01-15",
  "end_date": "2024-01-20",
  "participants": [],
  "created_by": 1,
  "created_at": "2024-01-01T00:00:00"
}
```

---

### 4.5 更新任务

```
PUT /api/tasks/{id}
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | ❌ | 任务标题 |
| description | string | ❌ | 任务描述 |
| status | string | ❌ | 状态：pending/in_progress/completed |
| priority | string | ❌ | 优先级：high/medium/low |
| progress | integer | ❌ | 进度 (0-100) |
| start_date | string | ❌ | 开始日期 |
| end_date | string | ❌ | 结束日期 |

**响应**:
- `200 OK`
```json
{ "message": "Task updated successfully" }
```

---

### 4.6 删除任务

```
DELETE /api/tasks/{id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{ "message": "Task deleted successfully" }
```

---

### 4.7 加入任务

```
POST /api/tasks/{id}/join
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{ "message": "Joined task successfully" }
```

---

### 4.8 退出任务

```
POST /api/tasks/{id}/leave
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{ "message": "Left task successfully" }
```

---

### 4.9 获取任务评论

```
GET /api/tasks/{id}/comments
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "user_id": 1,
    "username": "user1",
    "nickname": "User",
    "avatar": null,
    "content": "这是一条评论",
    "reply_to": null,
    "created_at": "2024-01-15T12:00:00"
  }
]
```

---

### 4.10 添加任务评论

```
POST /api/tasks/{id}/comments
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | ✅ | 评论内容 |
| reply_to | integer | ❌ | 回复的评论ID |

**响应**:
- `201 Created`
```json
{
  "id": 1,
  "message": "Comment added successfully",
  "created_at": "2024-01-15T12:00:00"
}
```

---

### 4.11 获取任务聊天消息

```
GET /api/tasks/{id}/messages
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "user_id": 1,
    "username": "user1",
    "nickname": "User",
    "avatar": null,
    "content": "消息内容",
    "created_at": "2024-01-15T12:00:00"
  }
]
```

---

### 4.12 获取任务活动记录

```
GET /api/tasks/{id}/activities
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "user_id": 1,
    "username": "user1",
    "nickname": "User",
    "avatar": null,
    "action": "created_task",
    "detail": { "title": "任务1" },
    "created_at": "2024-01-15T12:00:00"
  }
]
```

---

### 4.13 创建任务链接

```
POST /api/tasks/links
```
🔒 **需要认证**

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| source | integer | ✅ | 源任务ID |
| target | integer | ✅ | 目标任务ID |
| type | string | ❌ | 链接类型：0(F-S)/1(S-S)/2(F-F)/3(S-F) |

**响应**:
- `201 Created`
```json
{ "id": 1, "message": "Link created" }
```

---

### 4.14 删除任务链接

```
DELETE /api/tasks/links/{id}
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{ "message": "Link deleted" }
```

---

## 5. 文件模块 (Files)

**前缀**: `/api/files`

### 5.1 上传文件

```
POST /api/files/upload
```
🔒 **需要认证**（需为团队成员）

**Content-Type**: `multipart/form-data`

**表单字段**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file | file | ✅ | 文件 |
| team_id | integer | ❌ | 团队ID（可从 task_id 推断） |
| task_id | integer | ❌ | 关联的任务ID |
| resource_id | integer | ❌ | 关联的资源ID |
| message_id | integer | ❌ | 关联的消息ID |
| timeline_event_id | integer | ❌ | 关联的时间轴事件ID |

**响应**:
- `201 Created`
```json
{
  "id": 1,
  "uid": "abc123def456",
  "filename": "document.pdf",
  "url": "/api/files/abc123def456",
  "message": "File uploaded successfully"
}
```

---

### 5.2 获取任务文件列表

```
GET /api/files?task_id={task_id}
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "uid": "abc123def456",
    "filename": "document.pdf",
    "filesize": 1024000,
    "created_at": "2024-01-15T12:00:00",
    "url": "/api/files/abc123def456"
  }
]
```

---

### 5.3 下载文件

```
GET /api/files/{uid}?inline={inline}
```
🔒 **需要认证**（需为团队成员）

**参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| inline | string | ❌ | 设为 "true" 在浏览器内显示 |

**响应**: 文件内容（作为附件或内联显示）

---

### 5.4 删除文件

```
DELETE /api/files/{uid}
```
🔒 **需要认证**（仅上传者可删除）

**响应**:
- `200 OK`
```json
{ "message": "File deleted successfully" }
```

---

## 6. 通知模块 (Notifications)

**前缀**: `/api/notifications`

### 6.1 获取用户通知列表

```
GET /api/notifications
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "type": "task_update",
    "content": "任务 \"设计稿\" 已更新",
    "related_id": 1,
    "is_read": false,
    "created_at": "2024-01-15T12:00:00"
  }
]
```

---

### 6.2 标记通知为已读

```
PUT /api/notifications/{id}/read
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{ "message": "Marked as read" }
```

---

### 6.3 标记所有通知为已读

```
PUT /api/notifications/read-all
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{ "message": "All marked as read" }
```

---

## 7. 资源模块 (Resources)

**前缀**: `/api/resources`

### 7.1 获取团队资源列表

```
GET /api/resources?team_id={team_id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "title": "项目规范文档",
    "content": "## 规范内容...",
    "created_at": "2024-01-15T12:00:00",
    "updated_at": "2024-01-16T12:00:00"
  }
]
```

---

### 7.2 创建资源

```
POST /api/resources
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| team_id | integer | ✅ | 团队ID |
| title | string | ✅ | 资源标题 |
| content | string | ❌ | 资源内容（支持Markdown） |

**响应**:
- `201 Created`
```json
{ "id": 1, "message": "Resource created successfully" }
```

---

### 7.3 获取资源详情

```
GET /api/resources/{id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
{
  "id": 1,
  "team_id": 1,
  "title": "项目规范文档",
  "content": "## 规范内容...",
  "created_at": "2024-01-15T12:00:00",
  "updated_at": "2024-01-16T12:00:00"
}
```

---

### 7.4 更新资源

```
PUT /api/resources/{id}
```
🔒 **需要认证**（仅创建者或团队创建者）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | ❌ | 资源标题 |
| content | string | ❌ | 资源内容 |

**响应**:
- `200 OK`
```json
{ "message": "Resource updated successfully" }
```

---

### 7.5 删除资源

```
DELETE /api/resources/{id}
```
🔒 **需要认证**（仅创建者或团队创建者）

**响应**:
- `200 OK`
```json
{ "message": "Resource deleted successfully" }
```

---

## 8. 时间轴模块 (Timeline)

**前缀**: `/api/timeline`

### 8.1 获取团队时间轴

```
GET /api/timeline/team/{team_id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "title": "项目启动",
    "description": "项目正式启动",
    "event_date": "2024-01-15T10:00:00",
    "created_at": "2024-01-15T10:00:00",
    "created_by": 1,
    "creator_name": "user1",
    "creator_avatar": "/uploads/avatar.jpg",
    "files": [
      {
        "id": 1,
        "uid": "abc123",
        "filename": "kickoff.pdf",
        "url": "/api/files/abc123"
      }
    ]
  }
]
```

---

### 8.2 创建时间轴事件

```
POST /api/timeline
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| team_id | integer | ✅ | 团队ID |
| title | string | ✅ | 事件标题 |
| description | string | ❌ | 事件描述 |
| event_date | string | ❌ | 事件日期 (ISO格式或YYYY-MM-DD) |

**响应**:
- `201 Created`
```json
{ "id": 1, "message": "Timeline event created successfully" }
```

---

### 8.3 更新时间轴事件

```
PUT /api/timeline/{event_id}
```
🔒 **需要认证**（仅创建者）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| title | string | ❌ | 事件标题 |
| description | string | ❌ | 事件描述 |
| event_date | string | ❌ | 事件日期 |

**响应**:
- `200 OK`
```json
{ "message": "Timeline event updated successfully" }
```

---

### 8.4 删除时间轴事件

```
DELETE /api/timeline/{event_id}
```
🔒 **需要认证**（仅创建者）

**响应**:
- `200 OK`
```json
{ "message": "Event deleted successfully" }
```

---

## 9. 学习进度模块 (Learning)

**前缀**: `/api/learning`

### 9.1 获取团队学习进度

```
GET /api/learning/team/{team_id}
```
🔒 **需要认证**（需为团队成员）

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "user_id": 1,
    "user_name": "user1",
    "user_avatar": "/uploads/avatar.jpg",
    "content": "今天学习了 React Hooks",
    "progress": 50,
    "created_at": "2024-01-15T18:00:00"
  }
]
```

---

### 9.2 提交学习进度

```
POST /api/learning
```
🔒 **需要认证**（需为团队成员）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| team_id | integer | ✅ | 团队ID |
| content | string | ✅ | 学习内容描述 |
| progress | integer | ❌ | 进度百分比 (0-100)，默认0 |

**响应**:
- `201 Created`
```json
{
  "id": 1,
  "message": "Learning progress updated successfully",
  "created_at": "2024-01-15T18:00:00"
}
```

---

### 9.3 更新学习进度条目

```
PUT /api/learning/{id}
```
🔒 **需要认证**（仅本人可编辑）

**请求体**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | ❌ | 学习内容描述 |

**响应**:
- `200 OK`
```json
{ "message": "Updated successfully" }
```

---

### 9.4 删除学习进度条目

```
DELETE /api/learning/{id}
```
🔒 **需要认证**（仅本人可删除）

**响应**:
- `200 OK`
```json
{ "message": "Deleted successfully" }
```

---

## 10. 仪表盘模块 (Dashboard)

**前缀**: `/api/dashboard`

### 10.1 获取用户统计数据

```
GET /api/dashboard/stats
```
🔒 **需要认证**

**响应**:
- `200 OK`
```json
{
  "teams": 3,
  "projects": 5,
  "tasks": 12,
  "completed": 8
}
```

---

### 10.2 获取最近任务

```
GET /api/dashboard/recent-tasks
```
🔒 **需要认证**

**说明**: 返回用户参与或创建的最近 5 个未完成任务

**响应**:
- `200 OK`
```json
[
  {
    "id": 1,
    "title": "设计登录页面",
    "status": "in_progress",
    "priority": "high",
    "project_name": "Web App",
    "progress": 60,
    "created_at": "2024-01-15T10:00:00"
  }
]
```

---

## 11. WebSocket 事件

**连接地址**: `ws://<host>:<port>`

使用 Socket.IO 协议进行实时通信。

### 11.1 加入团队聊天室

**事件名**: `team:join`

**发送数据**:
```json
{
  "token": "<JWT_TOKEN>",
  "team_id": 1
}
```

**错误响应**:
```json
{ "message": "Authentication failed" }
{ "message": "Access denied" }
```

---

### 11.2 离开团队聊天室

**事件名**: `team:leave`

**发送数据**:
```json
{
  "token": "<JWT_TOKEN>",
  "team_id": 1
}
```

---

### 11.3 发送团队消息

**事件名**: `team:message`

**发送数据**:
```json
{
  "token": "<JWT_TOKEN>",
  "team_id": 1,
  "content": "Hello everyone!"
}
```

**广播事件**: `team:message`

**广播数据**:
```json
{
  "id": 1,
  "user_id": 1,
  "username": "user1",
  "nickname": "User One",
  "avatar": "/uploads/avatar.jpg",
  "content": "Hello everyone!",
  "created_at": "2024-01-15T12:00:00"
}
```

---

## 通用响应状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（Token无效或过期） |
| 403 | 禁止访问（无权限） |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 数据模型

### User (用户)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| username | String(50) | 用户名 (唯一) |
| email | String(100) | 邮箱 (唯一) |
| student_id | String(20) | 学号 (唯一) |
| real_name | String(50) | 真实姓名 |
| nickname | String(50) | 昵称 |
| avatar | String(255) | 头像URL |

### Team (团队)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| name | String(100) | 团队名称 |
| description | Text | 团队描述 |
| avatar | String(255) | 团队头像 |
| invite_code | String(20) | 邀请码 (唯一) |
| creator_id | Integer | 创建者ID |

### Project (项目)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| team_id | Integer | 所属团队ID |
| name | String(100) | 项目名称 |
| description | Text | 项目描述 |
| status | String(20) | 状态: active/completed/archived |
| start_date | Date | 开始日期 |
| end_date | Date | 结束日期 |

### Task (任务)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| parent_id | Integer | 父任务ID (子任务) |
| project_id | Integer | 所属项目ID |
| title | String(200) | 任务标题 |
| description | Text | 任务描述 |
| status | String(20) | 状态: pending/in_progress/completed |
| priority | String(10) | 优先级: high/medium/low |
| progress | Integer | 进度 (0-100) |
| start_date | Date | 开始日期 |
| end_date | Date | 结束日期 |
| level | Integer | 层级深度 |
| sort_order | Integer | 排序顺序 |

### TaskLink (任务链接)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| source | Integer | 源任务ID |
| target | Integer | 目标任务ID |
| type | String(1) | 类型: 0(F-S)/1(S-S)/2(F-F)/3(S-F) |

### File (文件)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| uid | String(36) | 唯一标识 (用于URL) |
| team_id | Integer | 所属团队ID |
| task_id | Integer | 关联任务ID |
| resource_id | Integer | 关联资源ID |
| message_id | Integer | 关联消息ID |
| timeline_event_id | Integer | 关联时间轴事件ID |
| filename | String(255) | 原始文件名 |
| filepath | String(500) | 存储路径 |
| filesize | Integer | 文件大小 (bytes) |
| mimetype | String(100) | MIME类型 |
| uploader_id | Integer | 上传者ID |

### Notification (通知)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| user_id | Integer | 接收用户ID |
| type | String(50) | 通知类型 |
| content | Text | 通知内容 |
| related_id | Integer | 关联资源ID |
| is_read | Boolean | 是否已读 |

### TimelineEvent (时间轴事件)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| team_id | Integer | 所属团队ID |
| project_id | Integer | 关联项目ID |
| created_by | Integer | 创建者ID |
| title | String(200) | 事件标题 |
| description | Text | 事件描述 |
| event_date | DateTime | 事件日期 |

### LearningProgress (学习进度)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| team_id | Integer | 所属团队ID |
| user_id | Integer | 用户ID |
| content | Text | 学习内容 |
| progress | Integer | 进度 (0-100) |

### TeamResource (团队资源)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| team_id | Integer | 所属团队ID |
| user_id | Integer | 创建者ID |
| title | String(200) | 资源标题 |
| content | Text | 资源内容 (Markdown) |
