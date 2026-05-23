# Google Cloud Platform (GCP) — Overview & Quick Reference

A practical guide to the most important GCP services, how they fit together, and how to work with them through the Console and the `gcloud` CLI.

---

## Getting Started — Creating Your GCP Account

Before you can set up an organization, folders, or any resources, you need a Google Cloud account. This is free and takes just a few minutes.

### Step 1 — Create a Google Account (If You Don't Have One)

You need a Google account to use GCP. If you already have one (Gmail, Google Workspace, or any Google login), skip to Step 2.

1. Go to [https://accounts.google.com/signup](https://accounts.google.com/signup).
2. Fill in your name, choose a username (this creates a `@gmail.com` address), and set a password.
3. Complete the verification (phone number) and agree to the terms.

> **Note:** You can also use an existing non-Gmail email as your Google account. On the signup page, click **Use my current email address instead** and enter your existing email (e.g., `you@outlook.com`). Google will send a verification code to that address. This gives you a Google account without creating a new Gmail inbox.

### Step 2 — Sign Up for Google Cloud Platform

1. Go to [https://cloud.google.com](https://cloud.google.com) and click **Get started for free** (or **Start free** / **Go to console**).
2. Sign in with your Google account.
3. You'll be asked to agree to the Google Cloud Terms of Service — review and accept.
4. Enter your **country**, confirm your account type (**Individual** or **Business**), and provide your contact details.
5. Enter a **payment method** (credit or debit card). Google will place a small temporary authorization hold to verify the card — you will **not** be charged.
6. Click **Start my free trial**.

### Step 3 — Understand the Free Tier

When you create your GCP account, you automatically get:

- **$300 in free credits** valid for **90 days** — use these on any GCP service.
- **Always Free tier** — certain resources that remain free even after the trial ends, including:
  - 1 `e2-micro` Compute Engine VM per month (in select US regions)
  - 5 GB of Cloud Storage (Standard, in select US regions)
  - 1 GB of BigQuery queries per month
  - 2 million Cloud Function invocations per month
  - And more — see the full list at [https://cloud.google.com/free](https://cloud.google.com/free)

During the free trial, GCP will **not** auto-charge you when credits run out. You must manually upgrade to a paid account to continue using services beyond the trial. This means you can experiment safely without worrying about a surprise bill.

### Step 4 — Explore the Console

Once your account is active, you land in the [Google Cloud Console](https://console.cloud.google.com). This is the web-based dashboard where you manage everything. Take a moment to orient yourself:

- **Project selector** (top bar) — shows your current project. GCP auto-creates a default project called `My First Project` when you sign up.
- **Navigation menu** (hamburger icon, top left) — access to all GCP services organized by category (Compute, Storage, Networking, etc.).
- **Cloud Shell** (terminal icon, top right) — a free, browser-based terminal with `gcloud` pre-installed. Great for quick commands without installing anything locally.
- **Notifications** (bell icon) — shows the status of long-running operations like VM creation.
- **Search bar** (top) — search for services, documentation, or resources by name.

### Step 5 — Install the gcloud CLI (Optional but Recommended)

Cloud Shell works for quick tasks, but for serious work you'll want the CLI installed locally. See the [Setting Up the gcloud CLI](#setting-up-the-gcloud-cli) section later in this guide for full installation instructions on macOS, Windows, Linux, and Docker.

Quick start:

```bash
# macOS
brew install --cask google-cloud-sdk

# Windows
winget install Google.CloudSDK

# Initialize and log in
gcloud init
```

### What You Have So Far

At this point you have:

- A Google account
- A GCP account with $300 in free credits
- A default project (`My First Project`)
- Access to the Console and Cloud Shell
- Optionally, the `gcloud` CLI installed locally

This is enough to start using GCP immediately — you can create VMs, storage buckets, and databases right now under your default project. However, if you want proper organizational structure with folders, centralized IAM, and multi-project governance, continue to the next section to set up an organization.

---

## Setting Up a GCP Organization

A GCP Organization is the top of the resource hierarchy. It gives you centralized control over all folders, projects, and resources through org-level IAM policies and governance. Without an organization, you can still use GCP (projects exist standalone), but you lose the ability to create folders, enforce organization policies, and manage everything from a single root.

**You cannot create an organization from a personal Gmail account.** An organization is automatically provisioned when you verify a domain through **Google Cloud Identity** or **Google Workspace**.

### What You Need

- **A domain you own** (e.g., `cognitech.dev`, `mycompany.com`). The domain can be registered anywhere — Google Domains, AWS Route 53, Namecheap, Cloudflare, GoDaddy, etc. It doesn't matter where it lives.
- **Access to the domain's DNS settings** to add a verification record.

### Option A: Cloud Identity Free (Recommended)

This is the free path. You get an organization, centralized user management, and IAM — without paying for Google Workspace apps like Gmail or Drive.

**Step 1 — Sign up for Cloud Identity**

1. Go to [https://cloud.google.com/identity/docs/set-up-cloud-identity-admin](https://cloud.google.com/identity/docs/set-up-cloud-identity-admin).
2. Click through to the Cloud Identity Free signup.
3. Enter your business name and the domain you own (e.g., `cognitech.dev`).
4. Create your first admin account — this will be `admin@yourdomain.com` (or whatever username you choose). This user becomes the **Super Admin** of your organization.

**Step 2 — Verify your domain**

Google needs to confirm you own the domain. It will give you a TXT record to add to your DNS.

If your domain is on **AWS Route 53:**

1. Copy the verification TXT record Google provides (looks like `google-site-verification=XXXXXXXXXXXX`).
2. Log into the **AWS Console → Route 53 → Hosted Zones** → select your domain.
3. Click **Create Record**.
4. Set **Record type** to **TXT**.
5. Leave the **Record name** blank (or `@` for the root domain).
6. Paste the verification string into the **Value** field. Wrap it in double quotes: `"google-site-verification=XXXXXXXXXXXX"`.
7. Set **TTL** to 300 (5 minutes).
8. Click **Create records**.

If your domain is on **another registrar** (Namecheap, Cloudflare, GoDaddy, etc.):

1. Log into your registrar's dashboard and find the DNS management page for your domain.
2. Add a new **TXT record** at the root (`@`).
3. Paste the Google verification string as the value.
4. Save and wait for propagation (usually a few minutes, can take up to an hour).

**Step 3 — Complete verification**

1. Go back to the Google Cloud Identity setup page.
2. Click **Verify**. If DNS has propagated, verification succeeds immediately.
3. Google automatically creates your **Organization resource** tied to the domain.

**Step 4 — Log in and confirm**

1. Sign into the [GCP Console](https://console.cloud.google.com) using your new `admin@yourdomain.com` account.
2. At the top of the page, click the project selector drop-down — you should now see your organization listed at the top of the hierarchy.
3. Verify from the CLI:

```bash
gcloud auth login  # log in with admin@yourdomain.com
gcloud organizations list
```

You should see output like:

```
DISPLAY_NAME    ID              DIRECTORY_CUSTOMER_ID
cognitech.dev   123456789012    C0xxxxxxx
```

### Option B: Google Workspace (If You Also Want Email, Drive, etc.)

If you want custom email (`you@yourdomain.com`), Google Drive, Calendar, and the full Workspace suite, sign up at [https://workspace.google.com](https://workspace.google.com) instead. Plans start around $7/user/month. The domain verification process is identical to Option A. The GCP organization is created automatically as a side effect of verifying your domain.

> **Sign-up note:** During the Workspace or Cloud Identity registration, you use any existing email you already have (e.g., your personal Gmail) just for the initial contact. The important part is when you **create your admin account** — that's where your domain comes in. You'll create `admin@yourdomain.com` and that becomes your real GCP identity going forward.

### Troubleshooting — "You do not have the required permission to create folders"

After creating your organization, you may still get this error:

```
You do not have the required "resourcemanager.folders.create" permission
to create folders in this location.
```

This is a common issue. Being a **Super Admin** in Google Admin (`admin.google.com`) does **not** automatically grant you all GCP IAM roles. You need to explicitly assign GCP roles to your admin account.

**Check 1 — Verify you're on the right account.**

Look at the profile icon in the top-right corner of the GCP Console. If you have multiple Google accounts, the Console might be using your personal Gmail instead of your `admin@yourdomain.com` account. Switch accounts if needed.

**Check 2 — Make sure the organization is selected.**

In the **Manage Resources** page, the drop-down at the top must show your organization (e.g., `cognitechllc.org`), not "No organization" or an old project from another account.

**Fix — Grant yourself the required GCP roles.**

Open **Cloud Shell** (terminal icon in the top-right of the Console) and run:

```bash
# Find your organization ID
gcloud organizations list

# Grant yourself Organization Administrator
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
  --member="user:admin@yourdomain.com" \
  --role="roles/resourcemanager.organizationAdmin"

# Grant yourself Folder Admin
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
  --member="user:admin@yourdomain.com" \
  --role="roles/resourcemanager.folderAdmin"
```

Alternatively, do it through the Console:

1. Go to **IAM & Admin → IAM**.
2. Use the resource picker at the top to select your **organization** (not a project).
3. Click **Grant Access**.
4. Enter your admin email as the principal.
5. Add the roles **Organization Administrator** and **Folder Admin**.
6. Click **Save**.

After granting these roles, go back to **Manage Resources**, confirm your organization is selected, and try creating the folder again. It should work immediately.

> **Why this happens:** Google keeps the Google Admin (admin.google.com) identity layer separate from GCP IAM. Super Admin gives you full control over users, groups, and domain settings, but GCP resource permissions like creating folders, projects, and setting IAM policies require explicit GCP role assignments. This is by design — it lets organizations separate admin duties between identity administrators and cloud infrastructure administrators.

### Troubleshooting — "Domain Restricted Sharing" Policy Blocking IAM Grants

When trying to grant IAM roles to external accounts (e.g., a personal `@gmail.com` account), you may see this error:

```
The 'Domain Restricted Sharing' organization policy
(constraints/iam.allowedPolicyMemberDomains) is enforced. Only principals
in allowed domains can be added as principals in the policy.
```

This means your organization has the **Domain Restricted Sharing** policy enabled, which only allows IAM roles to be granted to accounts within your organization's domain (e.g., `@cognitechllc.org`). GCP often enables this by default on new organizations.

**Option 1 — Use org accounts instead (more secure)**

Rather than opening up access to external domains, create user accounts within your organization:

1. Go to [admin.google.com](https://admin.google.com) → **Directory → Users**.
2. Click **Add new user**.
3. Create accounts like `dev@yourdomain.com` or `yourname@yourdomain.com`.
4. Use those domain accounts when granting IAM roles — the policy will allow them.

**Option 2 — Disable the restriction (if you need external account access)**

You need the **Organization Policy Administrator** role first. Grant it to yourself via Cloud Shell:

```bash
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
  --member="user:admin@yourdomain.com" \
  --role="roles/orgpolicy.policyAdmin"
```

If that command fails, go to [admin.google.com](https://admin.google.com) → **Account → Admin roles** → create a new role with **Google Cloud → Organization Policy Administrator** privileges enabled, and assign it to your admin account.

Once you have the role, modify the policy:

**Console:**

1. Go to **IAM & Admin → Organization Policies**.
2. Make sure your **organization** is selected at the top.
3. Search for **Domain Restricted Sharing** (or `iam.allowedPolicyMemberDomains`).
4. Click on the policy.
5. Click **Manage Policy** → **Edit**.
6. Select **Override parent's policy**.
7. Select **Replace**.
8. Under Rules, change it to **Allow All**.
9. Click **Set Policy** at the bottom of the page.
10. **Wait 2–3 minutes** for the change to propagate before trying the IAM grant again.

> **Important:** Make sure you actually click **Set Policy** / **Save** at the bottom of the page. The change won't take effect until you do, and propagation can take a few minutes even after saving.

**CLI (alternative if the Console doesn't cooperate):**

```bash
# Create a policy file that resets to default (allow all domains)
cat > /tmp/policy.yaml << 'EOF'
constraint: constraints/iam.allowedPolicyMemberDomains
restoreDefault: {}
EOF

# Apply it
gcloud resource-manager org-policies set-policy /tmp/policy.yaml \
  --organization=ORGANIZATION_ID
```

**Verify the policy was applied:**

```bash
gcloud resource-manager org-policies describe \
  iam.allowedPolicyMemberDomains \
  --organization=ORGANIZATION_ID
```

After the policy change propagates, try granting the IAM role to the external account again.

> **Security recommendation:** While "Allow All" is fine during initial setup and learning, consider switching back to a restricted policy once you're in production. You can allow specific external domains (instead of all) by adding their Google Workspace customer IDs to the allowed list. This prevents accidental access leaks to unintended external accounts.

### After Your Organization Is Created — What to Do Next

Now that you can see your organization in the GCP Console, follow these steps in order to get your account fully set up.

#### Step 1 — Set Up Billing

Nothing runs on GCP without a billing account. Even free-tier usage requires one linked.

**Console:**

1. Go to [Billing](https://console.cloud.google.com/billing) in the GCP Console.
2. Click **Create Account** (or **Manage billing accounts** → **Create Account**).
3. Give it a descriptive name (e.g., `Cognitech - Main Billing`).
4. Select your **Country** and **Currency**.
5. Under **Organization**, select your newly created organization from the drop-down — this ties the billing account to your org so org admins can manage it centrally.
6. Click **Continue** and enter your payment method (credit/debit card or bank account).
7. Click **Submit and enable billing**.

**CLI:**

```bash
# Billing accounts are created through the Console, but you can verify it exists:
gcloud billing accounts list

# You should see something like:
# ACCOUNT_ID            NAME                    OPEN   MASTER_ACCOUNT_ID
# 01XXXX-XXXXXX-XXXXXX  Cognitech - Main Billing  True
```

> **Tip:** If you're just getting started, GCP offers a [$300 free trial credit](https://cloud.google.com/free) valid for 90 days. You still need to add a payment method, but you won't be charged until the credits run out and you explicitly upgrade to a paid account.

#### Step 2 — Design Your Folder Structure

Before creating folders, plan a structure that fits your needs. A common pattern for a small-to-medium setup:

```
Organization (yourdomain.com)
├── Production/
│   ├── project-app-prod
│   └── project-data-prod
├── Non-Production/
│   ├── Staging/
│   │   └── project-app-staging
│   └── Development/
│       └── project-app-dev
├── Shared Services/
│   ├── project-networking
│   └── project-security
└── Sandbox/
    └── project-experiments
```

Key principles: keep **production isolated** from everything else, use a **Shared Services** folder for cross-cutting resources like networking and logging, and give developers a **Sandbox** folder where they can experiment without affecting anything.

#### Step 3 — Create Your Folders

**Console:**

1. Go to [Manage Resources](https://console.cloud.google.com/cloud-resource-manager) in the GCP Console.
2. Make sure your organization is selected in the drop-down at the top.
3. Click **Create Folder**.
4. Enter a name (e.g., `Production`).
5. Under **Organization / Folder**, confirm it's set to your organization.
6. Click **Create**.
7. Repeat for each top-level folder (`Non-Production`, `Shared Services`, `Sandbox`).
8. To create nested folders (e.g., `Staging` under `Non-Production`), click into the parent folder first, then click **Create Folder** again.

**CLI:**

```bash
# First, get your organization ID
gcloud organizations list
# Note the ID (e.g., 123456789012)

# Create top-level folders
gcloud resource-manager folders create \
  --display-name="Production" \
  --organization=123456789012

gcloud resource-manager folders create \
  --display-name="Non-Production" \
  --organization=123456789012

gcloud resource-manager folders create \
  --display-name="Shared Services" \
  --organization=123456789012

gcloud resource-manager folders create \
  --display-name="Sandbox" \
  --organization=123456789012

# List your folders to get their IDs
gcloud resource-manager folders list --organization=123456789012

# Create nested folders (e.g., Staging under Non-Production)
gcloud resource-manager folders create \
  --display-name="Staging" \
  --folder=NON_PRODUCTION_FOLDER_ID

gcloud resource-manager folders create \
  --display-name="Development" \
  --folder=NON_PRODUCTION_FOLDER_ID
```

#### Step 4 — Create Your First Project and Link Billing

**Console:**

1. Go to [Manage Resources](https://console.cloud.google.com/cloud-resource-manager).
2. Click **Create Project**.
3. Enter a project name and a unique project ID.
4. Under **Location**, select the folder where this project should live (e.g., `Sandbox` for your first test project).
5. Click **Create**.
6. After the project is created, go to [Billing](https://console.cloud.google.com/billing) → **My Projects**.
7. Find the new project, click the three-dot menu under **Actions** → **Change billing**.
8. Select your billing account and click **Set Account**.

**CLI:**

```bash
# Create a project inside a folder
gcloud projects create my-first-project \
  --name="My First Project" \
  --folder=SANDBOX_FOLDER_ID

# Link it to your billing account
gcloud billing projects link my-first-project \
  --billing-account=BILLING_ACCOUNT_ID

# Verify the project is linked
gcloud billing projects describe my-first-project

# Enable some common APIs (they're off by default)
gcloud services enable compute.googleapis.com --project=my-first-project
gcloud services enable storage.googleapis.com --project=my-first-project
gcloud services enable container.googleapis.com --project=my-first-project
```

#### Step 5 — Set Up Org-Level IAM

Grant roles at the organization level so they apply across all folders and projects. As the Super Admin, you already have full access, but you'll want to set up roles for any team members.

**Console:**

1. Go to **IAM & Admin → IAM** in the GCP Console.
2. At the top, make sure you're viewing the **organization** (not a specific project) using the resource picker.
3. Click **Grant Access**.
4. Enter the user's email, select a role, and click **Save**.

**CLI:**

```bash
# Grant someone the ability to create folders
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
  --member="user:colleague@yourdomain.com" \
  --role="roles/resourcemanager.folderCreator"

# Grant someone the ability to create projects
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
  --member="user:colleague@yourdomain.com" \
  --role="roles/resourcemanager.projectCreator"

# Grant someone billing user access (so they can link projects to billing)
gcloud organizations add-iam-policy-binding ORGANIZATION_ID \
  --member="user:colleague@yourdomain.com" \
  --role="roles/billing.user"

# View the full org-level IAM policy
gcloud organizations get-iam-policy ORGANIZATION_ID
```

#### Step 6 — Set a Budget (Don't Skip This)

Setting a budget with alerts is essential to avoid surprise charges, especially when you're experimenting.

**Console:**

1. Go to [Billing](https://console.cloud.google.com/billing) → select your billing account.
2. Click **Budgets & alerts** in the left menu.
3. Click **Create Budget**.
4. Name it (e.g., `Monthly Spending Limit`).
5. Scope it to **All projects** (or select specific ones).
6. Set the budget amount (e.g., $50 for a sandbox, or whatever fits).
7. Keep the default alert thresholds at **50%**, **90%**, and **100%** — alerts go to billing admins by email.
8. Click **Finish**.

**CLI:**

```bash
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Monthly Spending Limit" \
  --budget-amount=50USD \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0
```

> **Important:** Budgets in GCP are **alerts only** — they don't automatically stop spending. If you want to hard-cap costs, you need to set up a Pub/Sub topic linked to the budget and a Cloud Function that disables billing on the project when the limit is hit. See [Programmatic budget notifications](https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications) for details.

#### Quick Checklist

After completing the steps above, you should have:

- [ ] Organization visible in the GCP Console
- [ ] Billing account created with a valid payment method
- [ ] Folder structure set up (Production, Non-Production, Shared Services, Sandbox)
- [ ] At least one project created and linked to billing
- [ ] Common APIs enabled on the project
- [ ] Org-level IAM configured for any team members
- [ ] Budget with alerts set up

You're now ready to start creating resources. The sections below cover each major GCP service in detail.

> **Tip:** You can manage users, groups, and security settings (like enforcing 2FA) through the [Google Admin Console](https://admin.google.com). This is separate from the GCP Console and is where you handle identity management for your organization.

---

## How GCP Is Organized

Everything in GCP lives inside a hierarchy: **Organization → Folders → Projects → Resources**. A *project* is the fundamental unit — billing, APIs, IAM permissions, and resources all attach to a project. You'll reference it constantly via its **Project ID** (globally unique string) or **Project Number**.

For guidance on structuring your hierarchy, see the [resource hierarchy overview](https://docs.cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects) and [Decide a resource hierarchy for your Google Cloud landing zone](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy).

#### GCP vs AWS — Resource Hierarchy Comparison

If you're coming from AWS, the hierarchy concepts map like this:

| GCP | AWS | Purpose |
|---|---|---|
| Organization | Organization (root) | Top-level entity tied to a domain |
| Folder | Organizational Unit (OU) | Grouping layer for policy inheritance |
| Project | Account | Isolation boundary, billing unit, where resources live |
| Resource | Resource | The actual VM, bucket, database, etc. |

**GCP Projects ≈ AWS Accounts.** A GCP project is the closest equivalent to an AWS account. Both serve as the fundamental isolation boundary where resources live, billing is tracked, and IAM policies are applied. Just like you'd spin up separate AWS accounts for prod, staging, and dev, you'd create separate GCP projects for each.

**GCP Folders ≈ AWS Organizational Units (OUs).** Folders in GCP map to OUs in AWS Organizations. Both exist purely for grouping and policy inheritance — they don't contain resources directly. You use them to organize projects (or accounts in AWS) by team, environment, or business unit, and IAM/org policies set at the folder level cascade down.

**Key difference — IAM scope:** In AWS, each account has its own root user and completely independent IAM namespace. Cross-account access requires role assumption (sts:AssumeRole). In GCP, IAM is unified across the entire organization — a user identity is the same across all projects, and access is granted through policy bindings at any level of the hierarchy (org, folder, or project). This makes cross-project access simpler in GCP compared to the cross-account role-assumption pattern in AWS.

### Projects

Projects are the fundamental operating unit in the Google Cloud resource hierarchy, sitting between folders (or the organization) and the actual resources like VMs and storage buckets. Understanding projects is essential because they serve four critical roles:

- **Primary service container** — all Google Cloud services (APIs) are enabled at the project level, and resources like Compute Engine instances or BigQuery datasets are created inside a project.
- **Trust boundary** — projects act as an isolation layer. By default, resources in one project don't have access to resources in another, creating a secure perimeter for different applications or environments.
- **Billing unit** — projects are the primary way organizations track, organize, and separate costs.
- **Policy attachment point** — while policies can inherit from folders, the project level is the most common place where IAM permissions are granted to developers and service accounts for day-to-day work.

#### Project Identifiers

Every project has three identifiers:

| Identifier | Description | Editable? |
|---|---|---|
| **Project name** | Human-readable label (4–30 characters). Does not need to be unique. | Yes, anytime |
| **Project ID** | Globally unique string (6–30 chars, lowercase letters/numbers/hyphens, must start with a letter, cannot end with a hyphen). | No — permanent after creation |
| **Project number** | Auto-generated numeric identifier. | No — assigned by Google |

> **Security note:** Don't include sensitive information (PII, security data) in project names or IDs — they appear in resource names and URLs throughout GCP.

Project ID requirements in detail: must be 6–30 characters, lowercase letters/numbers/hyphens only, must start with a letter, cannot end with a hyphen, cannot reuse a previously used ID (including deleted projects), and cannot contain restricted strings like `google` or `ssl`.

#### Creating a Project

To create a project you need the `resourcemanager.projects.create` permission, which is included in the **Project Creator** role (`roles/resourcemanager.projectCreator`). This role is granted by default to the entire domain of a new organization and to free trial users. See [Managing Default Organization Roles](https://docs.cloud.google.com/resource-manager/docs/default-access-control) for details on limiting this.

**Console:**

1. Go to [Manage Resources](https://console.cloud.google.com/cloud-resource-manager) in the Google Cloud console.
2. Select your organization from the drop-down at the top of the page (free trial users can skip this).
3. Click **Create Project**.
4. Enter a project name and select a billing account.
5. Set the parent organization or folder in the **Location** box (this determines where the project sits in the hierarchy).
6. Click **Create**.

**CLI:**

```bash
# Create a project
gcloud projects create my-project-id \
  --name="My Project" \
  --organization=ORGANIZATION_ID

# Create a project under a specific folder
gcloud projects create my-project-id \
  --name="My Project" \
  --folder=FOLDER_ID

# Create a project with tags
gcloud projects create my-project-id \
  --organization=ORGANIZATION_ID \
  --tags=123/environment=production,123/team=platform

# List all projects
gcloud projects list

# Describe a specific project
gcloud projects describe my-project-id

# Delete a project (enters a 30-day shutdown period)
gcloud projects delete my-project-id
```

### Folders

Folders sit between the organization and projects in the resource hierarchy. They let you group projects that share common IAM policies, organization policies, or simply belong to the same team, department, or environment. Folders can be nested up to 10 levels deep, so you can mirror your company's org structure as closely as you need.

A typical folder structure might look like this:

```
Organization (example.com)
├── Engineering/
│   ├── Production/
│   │   ├── project-api-prod
│   │   └── project-web-prod
│   ├── Staging/
│   │   └── project-staging
│   └── Dev/
│       └── project-sandbox
├── Data/
│   ├── project-bigquery-prod
│   └── project-analytics
└── Shared Services/
    ├── project-networking
    └── project-logging
```

IAM policies set on a folder are **inherited** by all projects and sub-folders beneath it. This makes folders the ideal place to grant team-wide access — give the engineering team Editor on the `Engineering` folder and every project inside automatically picks it up.

To manage folders you need the **Folder Admin** role (`roles/resourcemanager.folderAdmin`) or the **Folder Creator** role (`roles/resourcemanager.folderCreator`) at the organization or parent folder level.

**Console:**

1. Go to [Manage Resources](https://console.cloud.google.com/cloud-resource-manager) in the Google Cloud console.
2. Select your organization from the drop-down at the top.
3. Click **Create Folder**.
4. Enter a folder name (display name, does not need to be unique).
5. Under **Organization / Folder**, select where this folder should live in the hierarchy.
6. Click **Create**.

To move an existing project into a folder, check the box next to the project on the Manage Resources page, click **Move**, and select the destination folder.

**CLI:**

```bash
# Create a folder under the organization
gcloud resource-manager folders create \
  --display-name="Engineering" \
  --organization=ORGANIZATION_ID

# Create a nested folder under an existing folder
gcloud resource-manager folders create \
  --display-name="Production" \
  --folder=PARENT_FOLDER_ID

# List folders under the organization
gcloud resource-manager folders list --organization=ORGANIZATION_ID

# List sub-folders under a specific folder
gcloud resource-manager folders list --folder=PARENT_FOLDER_ID

# Move a project into a folder
gcloud projects move PROJECT_ID --folder=FOLDER_ID

# Move a folder under another folder
gcloud resource-manager folders move FOLDER_ID --folder=DEST_FOLDER_ID

# Update a folder's display name
gcloud resource-manager folders update FOLDER_ID \
  --display-name="New Name"

# Delete a folder (must be empty — move or delete all child projects/folders first)
gcloud resource-manager folders delete FOLDER_ID
```

### Billing Account

Nothing runs on GCP without a billing account. A billing account is linked to a payment method (credit card, invoice, etc.) and defines **who pays** for the resources consumed by projects. Every project must be associated with a billing account to use paid services.

Key concepts:

- **Billing account** — holds payment info and is linked to one or more projects. An organization can have multiple billing accounts (e.g., one per department or cost center).
- **Billing account types** — *Self-serve* (online, credit card) or *Invoiced* (offline, monthly invoicing for larger customers).
- **Budgets & alerts** — you can set budgets on a billing account or individual projects and receive email or Pub/Sub alerts when spending crosses thresholds (e.g., 50%, 90%, 100%).
- **Billing export** — export detailed billing data to BigQuery for analysis, or to Cloud Storage for archival. This is essential for cost management at scale.
- **Billing IAM roles** — `roles/billing.admin` (full control), `roles/billing.creator` (create new accounts), `roles/billing.user` (link projects to an account), `roles/billing.viewer` (view costs).

#### Setting Up a Billing Account

**Console:**

1. Go to [Billing](https://console.cloud.google.com/billing) in the Google Cloud console.
2. If you don't have a billing account yet, click **Create Account**.
3. Enter a name for the billing account (e.g., "Engineering - Production").
4. Select your country and currency.
5. Enter your payment method details.
6. Click **Submit and enable billing**.

#### Linking a Project to a Billing Account

**Console:**

1. Go to [Billing](https://console.cloud.google.com/billing) → **My Projects**.
2. Find the project you want to link.
3. Under the **Actions** column, click the three-dot menu → **Change billing**.
4. Select the billing account and click **Set Account**.

**CLI:**

```bash
# List all billing accounts you have access to
gcloud billing accounts list

# Describe a billing account
gcloud billing accounts describe BILLING_ACCOUNT_ID

# Link a project to a billing account
gcloud billing projects link PROJECT_ID \
  --billing-account=BILLING_ACCOUNT_ID

# Check which billing account a project is linked to
gcloud billing projects describe PROJECT_ID

# Unlink a project from billing (disables paid services)
gcloud billing projects unlink PROJECT_ID
```

#### Setting Up Budgets & Alerts

**Console:**

1. Go to [Billing](https://console.cloud.google.com/billing) → select your billing account.
2. Click **Budgets & alerts** in the left menu.
3. Click **Create Budget**.
4. Name the budget and scope it (all projects, specific projects, specific services, or specific labels).
5. Set the budget amount (a fixed dollar amount or based on last month's spend).
6. Configure alert thresholds (default is 50%, 90%, 100%) — alerts go to billing admins by email. Optionally connect a Pub/Sub topic for programmatic responses.
7. Click **Finish**.

**CLI:**

```bash
# Create a budget (requires the billing budgets API)
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Monthly Production Budget" \
  --budget-amount=1000USD \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0

# List budgets
gcloud billing budgets list --billing-account=BILLING_ACCOUNT_ID

# Describe a budget
gcloud billing budgets describe BUDGET_ID \
  --billing-account=BILLING_ACCOUNT_ID
```

#### Enabling Billing Export to BigQuery

Exporting billing data to BigQuery is strongly recommended — it gives you full SQL access to your cost data for dashboards and analysis.

**Console:**

1. Go to [Billing](https://console.cloud.google.com/billing) → select your billing account.
2. Click **Billing export** in the left menu.
3. Under the **BigQuery export** tab, click **Edit Settings**.
4. Select the project and dataset where you want the data exported (create a new dataset if needed).
5. Choose the export type: **Standard usage cost** (recommended), **Detailed usage cost**, or **Pricing**.
6. Click **Save**.

Once enabled, GCP automatically streams billing records into the BigQuery dataset. You can then query it:

```sql
SELECT
  project.id AS project_id,
  service.description AS service,
  SUM(cost) AS total_cost
FROM `my-project.my_dataset.gcp_billing_export_v1_XXXXXX`
WHERE invoice.month = '202605'
GROUP BY project_id, service
ORDER BY total_cost DESC;
```

### Setting Up the gcloud CLI

The `gcloud` CLI is your primary command-line tool for interacting with GCP. It's part of the **Google Cloud SDK**, which also includes `gsutil` (legacy Cloud Storage tool), `bq` (BigQuery), and `kubectl` (Kubernetes — installed separately).

#### Prerequisites

You need a Google account and a GCP project. If you don't have a project yet, you can create one during `gcloud init` or through the [Console](https://console.cloud.google.com).

#### Installation

**macOS:**

```bash
# Using Homebrew
brew install --cask google-cloud-sdk

# Or download the installer directly
curl https://sdk.cloud.google.com | bash
```

**Windows:**

Download and run the [Google Cloud SDK installer](https://cloud.google.com/sdk/docs/install#windows). Alternatively, using `winget` or `choco`:

```powershell
# Using winget
winget install Google.CloudSDK

# Using Chocolatey
choco install gcloudsdk
```

**Linux (Debian/Ubuntu):**

```bash
# Add the Cloud SDK repository
echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" | \
  sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  sudo tee /usr/share/keyrings/cloud.google.asc

# Install the SDK
sudo apt-get update && sudo apt-get install google-cloud-cli
```

**Linux (RHEL/CentOS/Fedora):**

```bash
# Add the repo
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install
sudo dnf install google-cloud-cli
```

**Docker:**

```bash
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:latest
docker run --rm -it gcr.io/google.com/cloudsdktool/google-cloud-cli gcloud version
```

#### Initial Setup

After installation, run `gcloud init` to walk through an interactive setup:

```bash
gcloud init
```

This will prompt you to log in, select (or create) a project, and set a default region/zone. It's the fastest way to get going. If you prefer to configure each piece manually:

```bash
# Authenticate your user account (opens a browser)
gcloud auth login

# Set your default project
gcloud config set project PROJECT_ID

# Set a default region and zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# Verify your configuration
gcloud config list
```

#### Authentication Methods

GCP CLI supports several authentication methods depending on the context:

```bash
# Interactive login (for your personal user account — opens a browser)
gcloud auth login

# Application Default Credentials (ADC) — used by client libraries and Terraform
gcloud auth application-default login

# Service account authentication (for CI/CD, scripts, non-interactive use)
gcloud auth activate-service-account SA_EMAIL \
  --key-file=/path/to/service-account-key.json

# Check who is currently authenticated
gcloud auth list

# Revoke credentials
gcloud auth revoke user@example.com
```

> **Best practice:** Use `gcloud auth login` for interactive CLI work and `gcloud auth application-default login` when running code locally that uses Google client libraries (Terraform, Python SDK, etc.). In CI/CD pipelines, use service account keys or workload identity federation.

#### Configurations (Multiple Profiles)

If you work across multiple projects, accounts, or organizations, you can create named configurations to switch between them quickly instead of re-running `gcloud config set` every time:

```bash
# Create a new named configuration
gcloud config configurations create work-prod

# Set properties on it
gcloud config set project my-prod-project
gcloud config set account admin@company.com
gcloud config set compute/region us-central1

# Create another configuration
gcloud config configurations create work-dev
gcloud config set project my-dev-project
gcloud config set account dev@company.com
gcloud config set compute/region us-east1

# List all configurations
gcloud config configurations list

# Switch between configurations
gcloud config configurations activate work-prod

# Use a specific config for a single command without switching
gcloud compute instances list --configuration=work-dev
```

#### Installing Additional Components

The SDK is modular — you can install extra components as needed:

```bash
# List available components
gcloud components list

# Install kubectl (Kubernetes CLI)
gcloud components install kubectl

# Install the App Engine extensions
gcloud components install app-engine-python

# Install beta and alpha commands
gcloud components install beta
gcloud components install alpha

# Update all installed components to the latest version
gcloud components update
```

#### Useful Day-to-Day Commands

```bash
# Get help on any command
gcloud help compute instances create
# or use the --help flag
gcloud compute instances create --help

# Format output as JSON, YAML, CSV, or table
gcloud projects list --format=json
gcloud projects list --format="table(projectId,name,projectNumber)"

# Filter results
gcloud compute instances list --filter="zone:us-central1-a AND status=RUNNING"

# Use --quiet to skip confirmation prompts (useful for scripts)
gcloud compute instances delete my-vm --zone=us-central1-a --quiet

# See the underlying REST API request a command makes (great for learning)
gcloud compute instances list --log-http

# Find the right command interactively
gcloud interactive  # requires: gcloud components install beta

# Check your current SDK version
gcloud version
```

For the full CLI reference, see the [gcloud CLI documentation](https://cloud.google.com/sdk/gcloud/reference) and the [gcloud cheat sheet](https://cloud.google.com/sdk/docs/cheatsheet).

---

## 1. IAM — Identity & Access Management

IAM controls **who** (identity) can do **what** (role/permissions) on **which resource**. The model is built on three concepts:

- **Members** — a Google account, service account, Google Group, or Cloud Identity domain.
- **Roles** — a named collection of permissions. GCP offers *Basic* roles (Owner, Editor, Viewer), *Predefined* roles (fine-grained, per-service), and *Custom* roles.
- **Policy bindings** — the glue that attaches a role to a member on a specific resource.

A **service account** is a special identity used by applications and VMs rather than humans. It has its own email address (`SA_NAME@PROJECT_ID.iam.gserviceaccount.com`) and can be granted roles just like a user.

### Console

Navigate to **IAM & Admin → IAM** in the left-hand menu. From here you can view all current bindings, add members, and assign roles using the role picker. Service accounts are managed under **IAM & Admin → Service Accounts**.

### CLI

```bash
# List all IAM bindings on the current project
gcloud projects get-iam-policy PROJECT_ID

# Grant a role to a user
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:jane@example.com" \
  --role="roles/editor"

# Create a service account
gcloud iam service-accounts create my-sa \
  --display-name="My Service Account"

# Grant a role to a service account
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:my-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# List predefined roles
gcloud iam roles list
```

---

## 2. Cloud Storage (the GCP equivalent of AWS S3)

Cloud Storage is GCP's object storage service. Data is organized into **buckets** (globally unique names) containing **objects** (files). Each bucket has a **storage class** that controls cost and availability:

| Storage Class | Use Case | Availability |
|---|---|---|
| Standard | Frequently accessed data | Highest |
| Nearline | Accessed less than once a month | High |
| Coldline | Accessed less than once a quarter | Moderate |
| Archive | Accessed less than once a year | Lowest cost |

Buckets also have a **location** (region, dual-region, or multi-region) that determines where the data physically lives.

### Console

Navigate to **Cloud Storage → Buckets**. From here you can create buckets, upload/download objects, set permissions, and configure lifecycle rules through a file-browser-style interface.

### CLI (gsutil and gcloud)

```bash
# Create a bucket
gcloud storage buckets create gs://my-unique-bucket-name \
  --location=us-central1

# Upload a file
gcloud storage cp local-file.txt gs://my-unique-bucket-name/

# List objects in a bucket
gcloud storage ls gs://my-unique-bucket-name/

# Download a file
gcloud storage cp gs://my-unique-bucket-name/local-file.txt ./downloaded.txt

# Make an object publicly readable
gcloud storage objects update gs://my-unique-bucket-name/local-file.txt \
  --add-acl-grant=entity=allUsers,role=READER

# Delete a bucket (must be empty, or add --recursive)
gcloud storage rm --recursive gs://my-unique-bucket-name/
```

> **Note:** The older `gsutil` command still works but `gcloud storage` is the recommended replacement.

---

## 3. Compute Engine — Virtual Machines

Compute Engine lets you run VMs on Google's infrastructure. Key concepts:

- **Machine type** — defines CPU and memory (e.g., `e2-medium` = 2 vCPUs, 4 GB RAM). Families include general-purpose (E2, N2), compute-optimized (C2), and memory-optimized (M2).
- **Image** — the OS disk snapshot a VM boots from (Debian, Ubuntu, Windows, etc.).
- **Zone / Region** — VMs run in a specific zone (e.g., `us-central1-a`).
- **Persistent Disk** — block storage attached to VMs. Can be Standard (HDD) or SSD.
- **Preemptible / Spot VMs** — much cheaper but can be reclaimed by Google with 30 seconds' notice. Great for fault-tolerant workloads.

### Console

Navigate to **Compute Engine → VM instances**. Click **Create Instance** to configure machine type, boot disk, networking, and startup scripts through a guided form. The equivalent `gcloud` command is shown at the bottom of the creation page — handy for learning the CLI.

### CLI

```bash
# Create a VM
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB

# List all VMs
gcloud compute instances list

# SSH into a VM
gcloud compute ssh my-vm --zone=us-central1-a

# Stop / Start / Delete
gcloud compute instances stop my-vm --zone=us-central1-a
gcloud compute instances start my-vm --zone=us-central1-a
gcloud compute instances delete my-vm --zone=us-central1-a

# Create a firewall rule (e.g. allow HTTP)
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --target-tags=http-server
```

---

## 4. VPC Networking

A **Virtual Private Cloud (VPC)** is your private network inside GCP. Every project gets a `default` VPC, but production workloads should use custom VPCs for better control.

- **Subnets** — regional IP ranges within a VPC.
- **Firewall rules** — stateful rules that allow or deny traffic to/from VM instances based on tags, service accounts, or IP ranges.
- **Cloud NAT** — lets VMs without external IPs reach the internet for outbound traffic.
- **Cloud Load Balancing** — distributes traffic across VMs or backends globally or regionally.

### Console

Navigate to **VPC network → VPC networks** to manage networks and subnets. Firewall rules live under **VPC network → Firewall**.

### CLI

```bash
# Create a custom VPC
gcloud compute networks create my-vpc --subnet-mode=custom

# Create a subnet
gcloud compute networks subnets create my-subnet \
  --network=my-vpc \
  --region=us-central1 \
  --range=10.0.0.0/24

# List firewall rules
gcloud compute firewall-rules list

# Create a firewall rule
gcloud compute firewall-rules create allow-ssh \
  --network=my-vpc \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0
```

---

## 5. GKE — Google Kubernetes Engine

GKE is Google's managed Kubernetes service. It handles the control plane, upgrades, and node scaling so you focus on deploying containers.

- **Autopilot mode** — Google manages the nodes entirely; you just deploy pods.
- **Standard mode** — you configure and manage node pools yourself.

### Console

Navigate to **Kubernetes Engine → Clusters**. Create a cluster in either Autopilot or Standard mode, then manage workloads under the **Workloads** tab.

### CLI

```bash
# Create an Autopilot cluster
gcloud container clusters create-auto my-cluster \
  --region=us-central1

# Get cluster credentials (configures kubectl)
gcloud container clusters get-credentials my-cluster \
  --region=us-central1

# Now use kubectl as normal
kubectl get nodes
kubectl get pods --all-namespaces

# Delete the cluster
gcloud container clusters delete my-cluster --region=us-central1
```

---

## 6. Cloud SQL & Databases

**Cloud SQL** is a fully managed relational database service supporting MySQL, PostgreSQL, and SQL Server. For NoSQL, GCP offers **Firestore** (document DB), **Bigtable** (wide-column), and **Spanner** (globally distributed relational).

### Console

Navigate to **SQL → Instances** to create and manage Cloud SQL instances. Connection details, backups, and replicas are configured here.

### CLI

```bash
# Create a PostgreSQL instance
gcloud sql instances create my-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1

# Create a database
gcloud sql databases create myapp --instance=my-db

# Set a user password
gcloud sql users set-password postgres \
  --instance=my-db \
  --password=MY_SECURE_PASSWORD

# Connect via Cloud SQL Proxy (recommended for local dev)
cloud-sql-proxy PROJECT_ID:us-central1:my-db
```

---

## 7. Cloud Functions & Cloud Run — Serverless

**Cloud Functions** — event-driven, single-purpose functions (similar to AWS Lambda). Write a function, deploy it, and GCP handles scaling.

**Cloud Run** — run any containerized application in a fully managed serverless environment. Scales to zero when idle.

### Console

Cloud Functions: **Cloud Functions → Create Function**. Cloud Run: **Cloud Run → Create Service**.

### CLI

```bash
# Deploy a Cloud Function (2nd gen, Python example)
gcloud functions deploy my-function \
  --gen2 \
  --runtime=python312 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=main \
  --source=./src

# Deploy a container to Cloud Run
gcloud run deploy my-service \
  --image=gcr.io/PROJECT_ID/my-image:latest \
  --region=us-central1 \
  --allow-unauthenticated

# List Cloud Run services
gcloud run services list
```

---

## 8. Monitoring & Logging (Cloud Operations Suite)

Formerly Stackdriver, the **Cloud Operations Suite** provides observability across all GCP resources.

- **Cloud Monitoring** — metrics, dashboards, alerting policies, uptime checks.
- **Cloud Logging** — centralized log ingestion, search, and export. Every GCP service writes logs here automatically.
- **Error Reporting** — groups and tracks application errors.
- **Cloud Trace** — distributed tracing for latency analysis.

### Console

Navigate to **Monitoring → Dashboards** for metrics, **Logging → Logs Explorer** to search logs. Alerting policies are under **Monitoring → Alerting**.

### CLI

```bash
# Read recent logs for a specific resource
gcloud logging read "resource.type=gce_instance" --limit=20

# Write a custom log entry
gcloud logging write my-log "Hello from the CLI" --severity=INFO

# List alerting policies
gcloud alpha monitoring policies list
```

---

## Quick Reference — Service Comparison with AWS

| GCP Service | AWS Equivalent | Purpose |
|---|---|---|
| Cloud Storage | S3 | Object storage |
| Compute Engine | EC2 | Virtual machines |
| GKE | EKS | Managed Kubernetes |
| Cloud SQL | RDS | Managed relational databases |
| Cloud Functions | Lambda | Serverless functions |
| Cloud Run | Fargate | Serverless containers |
| VPC | VPC | Private networking |
| IAM | IAM | Access management |
| Cloud Logging | CloudWatch Logs | Centralized logging |
| Cloud Monitoring | CloudWatch | Metrics and alerting |
| Pub/Sub | SNS/SQS | Messaging and event streaming |
| BigQuery | Redshift/Athena | Data warehouse and analytics |

---

## Infrastructure as Code for GCP

Since this repo focuses on IaC, here are the main tools for managing GCP resources declaratively:

- **Terraform / OpenTofu** — the most widely adopted IaC tool for GCP. Google maintains an official provider and publishes the Cloud Foundation Toolkit (CFT) with production-ready modules.
- **Infrastructure Manager** — Google's managed Terraform service. You push Terraform configs and GCP handles state, execution, and previews.
- **Config Connector** — manages GCP resources as Kubernetes custom resources, ideal for teams already running GKE.
- **Deployment Manager** — Google's original native IaC tool (YAML + Jinja2/Python templates). Still supported but considered legacy.
- **Pulumi** — alternative to Terraform that uses general-purpose languages (Python, TypeScript, Go).

---

## Useful Links

### Official Documentation

- [GCP Console](https://console.cloud.google.com)
- [GCP Documentation Home](https://cloud.google.com/docs)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [gcloud Cheat Sheet](https://cloud.google.com/sdk/docs/cheatsheet)
- [GCP Free Tier](https://cloud.google.com/free)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)
- [GCP Architecture Center](https://cloud.google.com/architecture)
- [GCP Solutions Library](https://cloud.google.com/docs/tutorials)
- [Google Cloud Blog](https://cloud.google.com/blog)
- [GCP Release Notes](https://cloud.google.com/release-notes)
- [GCP Status Dashboard](https://status.cloud.google.com)

### Service-Specific Documentation

- [IAM Documentation](https://cloud.google.com/iam/docs)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Compute Engine Documentation](https://cloud.google.com/compute/docs)
- [VPC Networking Documentation](https://cloud.google.com/vpc/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
- [Cloud Logging Documentation](https://cloud.google.com/logging/docs)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Cloud CDN Documentation](https://cloud.google.com/cdn/docs)
- [Cloud DNS Documentation](https://cloud.google.com/dns/docs)

### Infrastructure as Code

- [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Foundation Toolkit (CFT) Modules](https://cloud.google.com/docs/terraform/blueprints/terraform-blueprints)
- [GCP Terraform Samples on GitHub](https://github.com/GoogleCloudPlatform/terraform-google-modules)
- [Infrastructure Manager Docs](https://cloud.google.com/infrastructure-manager/docs)
- [Config Connector Docs](https://cloud.google.com/config-connector/docs)
- [Deployment Manager Docs](https://cloud.google.com/deployment-manager/docs)
- [Pulumi GCP Provider](https://www.pulumi.com/registry/packages/gcp/)

### Learning & Certification

- [Google Cloud Skills Boost (Qwiklabs)](https://www.cloudskillsboost.google)
- [Google Cloud Certifications](https://cloud.google.com/learn/certification)
- [Cloud Engineer Learning Path](https://cloud.google.com/learn/certification/cloud-engineer)
- [Cloud Architect Learning Path](https://cloud.google.com/learn/certification/cloud-architect)
- [Google Cloud on YouTube](https://www.youtube.com/@googlecloudtech)
- [GCP Awesome List (community)](https://github.com/GoogleCloudPlatform/awesome-google-cloud)

### Community & Support

- [Google Cloud Community](https://www.googlecloudcommunity.com)
- [Stack Overflow — GCP Tag](https://stackoverflow.com/questions/tagged/google-cloud-platform)
- [GCP Subreddit](https://www.reddit.com/r/googlecloud/)
- [Google Cloud Support Plans](https://cloud.google.com/support)
- [Google Cloud Issue Tracker](https://issuetracker.google.com/issues?q=componentid:187164)
