# TriipMate iOS

iOS app for the TriipMate travel companion platform.

---

## Connecting Your Xcode Project to This GitHub Repository

### Step 1 — Add Your GitHub Account to Xcode

1. Open **Xcode** on your Mac
2. Go to **Xcode → Settings** (or **Xcode → Preferences** on older versions)
3. Click the **Accounts** tab
4. Click the **+** button (bottom-left) and select **GitHub**
5. Enter your GitHub username and a **Personal Access Token**

> To create a token: GitHub → Settings → Developer Settings → Personal Access Tokens → Generate new token  
> Required scopes: `repo`, `workflow`

---

### Step 2 — Clone This Repository (New Setup)

If you haven't started the Xcode project yet:

1. In Xcode, go to **File → Clone...**  
   Or from the Welcome screen, click **Clone an existing project**
2. Enter the repository URL:
   ```
   https://github.com/anurmamedov/triipmate-ios.git
   ```
3. Choose a local folder and click **Clone**
4. Open the `.xcodeproj` or `.xcworkspace` file

---

### Step 3 — Link an Existing Xcode Project to This Repo

If you already have an Xcode project on your Mac:

```bash
# Navigate to your project folder
cd /path/to/your/TriipMate

# Initialize git (skip if already a git repo)
git init

# Add this GitHub repository as the remote
git remote add origin https://github.com/anurmamedov/triipmate-ios.git

# Pull the current state of the repo
git pull origin main --allow-unrelated-histories

# Stage all your project files
git add .

# Commit
git commit -m "Initial iOS project setup"

# Push to GitHub
git push -u origin main
```

---

### Step 4 — Verify the Connection in Xcode

1. Open your project in Xcode
2. Go to **Source Control → triipmate-ios** in the menu bar
3. You should see the repository listed with the branch name
4. Use **Source Control → Commit** and **Push** to sync changes going forward

---

## Development Workflow

```bash
# Create a new feature branch
git checkout -b feature/your-feature-name

# After making changes, commit and push
git add .
git commit -m "Add: description of your change"
git push -u origin feature/your-feature-name
```

## Requirements

- Xcode 15+
- iOS 16.0+ deployment target
- Swift 5.9+
