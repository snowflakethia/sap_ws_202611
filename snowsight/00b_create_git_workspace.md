# Step 0b - Create your Git workspace

**Goal:** see every training file in Snowsight, so you can open and run them without copying anything.
**Time:** 2 minutes. **Do this right after `00_bootstrap.sql`**, which created the API integration this step needs.

## Steps

1. In Snowsight, check that your role is **ACCOUNTADMIN** (your name, lower-left > Switch role).
2. Go to **Projects > Workspaces**.
3. Open the workspace menu at the top of the file list (it usually shows **My Workspace**).
   Under *Create Workspace*, select **From Git repository**.
4. Fill in the dialog:

   | Field | Value |
   | --- | --- |
   | Repository URL | `https://github.com/snowflakethia/sap_ws_202611.git` |
   | Workspace name | `gnn_training` |
   | API integration | `GNN_KIT_GITHUB` |
   | Authentication | **Public repository** |

5. Select **Create**.

### Shortcut (optional)
Instead of steps 2-5, paste this into your browser's address bar. Replace `<org>` and `<account>` with the
two parts after `app.snowflake.com/` in your current Snowsight address:

```
https://app.snowflake.com/<org>/<account>/#/workspaces?action=create_workspace_from_git_repo&remoteUrl=https%3A%2F%2Fgithub.com%2Fsnowflakethia%2Fsap_ws_202611.git&workspaceName=gnn_training&apiIntegration=GNN_KIT_GITHUB&authType=NONE
```

## Checkpoint 0b - expected outcome

| Check | What you should see |
| --- | --- |
| A | The workspace selector shows **gnn_training** |
| B | The file list shows the folders `snowsight/`, `sql/`, `data/`, `labs/` and `workspace/` |
| C | Opening `snowsight/01_stage1_account.sql` shows the file, starting with the comment `STAGE 1 - Account objects` |

## How to run each stage file from now on
1. In `gnn_training`, open the file (for example `snowsight/01_stage1_account.sql`).
2. In the editor's context bar, set the role to **ACCOUNTADMIN**. The warehouse can be left empty;
   the scripts choose their own.
3. Select **Run All** (Ctrl/Cmd + Shift + Enter).
4. Compare the **last result** with the expected checkpoint table, which is written at the top of the file
   and in `snowsight/README.md`.

> **Note:** this workspace is read-only toward GitHub. You can edit and run files, but you can't push changes
> to the public repository, and that's fine for the training. If the course is updated, open the
> **Changes** tab and select **Pull**.

## If something goes wrong

| Problem | Fix |
| --- | --- |
| `GNN_KIT_GITHUB` is not in the API integration list | Run `00_bootstrap.sql` first, and make sure your role is ACCOUNTADMIN |
| "Repository not found" | Check the URL: `https://github.com/snowflakethia/sap_ws_202611.git` |
| No **From Git repository** option | Your account still uses the classic Worksheets UI. Use Catalog > Git Repositories > `GNN_KIT` > *(file)* > **Copy into worksheet** for each file instead |
