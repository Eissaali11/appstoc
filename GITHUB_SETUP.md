# دليل رفع المشروع إلى GitHub

## ✅ الخطوات المكتملة

1. ✓ تم تهيئة Git في المشروع
2. ✓ تم إضافة جميع الملفات
3. ✓ تم إنشاء commit أولي
4. ✓ تم إنشاء README.md شامل

## 📋 الخطوات التالية

### 1. إنشاء مستودع على GitHub

1. اذهب إلى [GitHub](https://github.com)
2. اضغط على زر **"New"** أو **"+"** في الزاوية العلوية اليمنى
3. اختر **"New repository"**
4. املأ التفاصيل:
   - **Repository name**: `nuolipapp` (أو أي اسم تفضله)
   - **Description**: `Flutter Technician Mobile Application for Inventory Management`
   - **Visibility**: اختر **Private** (خاص) أو **Public** (عام)
   - **⚠️ لا تقم بتهيئة README أو .gitignore** (لأننا أضفناها بالفعل)
5. اضغط **"Create repository"**

### 2. ربط المشروع المحلي بـ GitHub

بعد إنشاء المستودع على GitHub، ستحصل على رابط مثل:
```
https://github.com/yourusername/nuolipapp.git
```

قم بتنفيذ الأوامر التالية:

```bash
# إضافة remote repository
git remote add origin https://github.com/yourusername/nuolipapp.git

# التحقق من الـ remote
git remote -v

# رفع الكود إلى GitHub
git branch -M main
git push -u origin main
```

### 3. إذا كان المستودع موجود بالفعل

إذا كان لديك مستودع موجود وترغب في ربطه:

```bash
# إضافة remote
git remote add origin https://github.com/yourusername/nuolipapp.git

# رفع الكود
git push -u origin main
```

### 4. استخدام GitHub CLI (اختياري)

إذا كان لديك GitHub CLI مثبت:

```bash
# إنشاء مستودع جديد وربطه
gh repo create nuolipapp --private --source=. --remote=origin --push
```

## 🔐 المصادقة

### استخدام Personal Access Token

1. اذهب إلى GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. اضغط **"Generate new token"**
3. اختر الصلاحيات:
   - ✅ `repo` (Full control of private repositories)
4. انسخ الـ Token
5. عند الـ push، استخدم الـ Token ككلمة مرور

### استخدام SSH (موصى به)

1. إنشاء SSH key:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. إضافة SSH key إلى GitHub:
```bash
# عرض المفتاح العام
cat ~/.ssh/id_ed25519.pub
```

3. اذهب إلى GitHub → Settings → SSH and GPG keys → New SSH key
4. الصق المفتاح وأضفه

5. تغيير remote إلى SSH:
```bash
git remote set-url origin git@github.com:yourusername/nuolipapp.git
```

## 📝 الأوامر المفيدة

### رفع التغييرات
```bash
git add .
git commit -m "وصف التغييرات"
git push
```

### سحب التحديثات
```bash
git pull
```

### عرض الحالة
```bash
git status
git log --oneline
```

### إنشاء branch جديد
```bash
git checkout -b feature/new-feature
git push -u origin feature/new-feature
```

## 🎯 الخطوات السريعة

```bash
# 1. إضافة remote (استبدل yourusername و nuolipapp)
git remote add origin https://github.com/yourusername/nuolipapp.git

# 2. رفع الكود
git push -u origin main

# 3. التحقق
git remote -v
```

## ⚠️ ملاحظات مهمة

1. **لا ترفع الملفات الحساسة**:
   - `.env` files
   - API keys
   - Passwords
   - Tokens

2. **تأكد من .gitignore**:
   - تم إعداد `.gitignore` بشكل صحيح
   - الملفات المؤقتة والـ build files مستثناة

3. **المساحة**:
   - تأكد من توفير مساحة كافية قبل الـ push

## 🆘 حل المشاكل

### خطأ: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/yourusername/nuolipapp.git
```

### خطأ: "failed to push some refs"
```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### خطأ: "authentication failed"
- تأكد من استخدام Personal Access Token
- أو قم بإعداد SSH keys

---

**بعد اكتمال الخطوات، سيكون المشروع متاحاً على GitHub! 🎉**
