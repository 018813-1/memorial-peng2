# memorial-peng2

彭聃龄先生线上缅怀室。

## 文件结构

```text
memorial-peng2/
├── index.html
├── supabase-setup.sql
└── assets/
    ├── 微信图片_20260506095430_32_1763.jpg
    └── secret-garden-piano.mp3
```

## 部署步骤

1. 在 Supabase 新建项目。
2. 打开 Supabase 的 SQL Editor，把 `supabase-setup.sql` 全部粘贴进去运行。
3. 复制 Supabase 的两个信息：
   - `Project URL`：左侧齿轮 Settings → Data API → Project URL。
   - `Publishable key`：左侧齿轮 Settings → API Keys → Publishable key 里的 default。不要复制 Secret key。
4. 打开 `index.html`，替换这两行：

```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL_HERE';
const SUPABASE_PUBLIC_KEY = 'YOUR_SUPABASE_PUBLISHABLE_KEY_HERE';
```

5. 把人物遗照和音乐文件放入 `assets/` 文件夹。
6. 把整个 `memorial-peng2` 上传到 GitHub，新建 GitHub Pages 即可。

## 注意

- 不需要访客登录。
- 访客身份通过浏览器本地生成的 visitor_key 识别；同一人换手机、换浏览器可能会被算作不同访客。
- 浏览器可能阻止“有声音的自动播放”，页面会自动尝试播放；失败时会提示访客点击音乐按钮开启。
