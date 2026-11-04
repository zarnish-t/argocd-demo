# Argo CD demo

A local Argo CD with three dummy services (orders, payments, notifications), laid out like our real setup: one Helm chart per service folder, picked up by an ApplicationSet, with a migration Job in sync wave 0, the Deployment in wave 1, and a CronJob.

Everything runs on your laptop in a throwaway minikube cluster. Nothing touches dev or prod.

## You need

`minikube` (with about 4 GB of memory free for it), `kubectl`, `helm` and `git`, plus a GitHub account.

## Setup (about 10 minutes)

1. Create a GitHub repo called `argocd-demo` and push the contents of this folder to its `main` branch. A public repo is simplest. For a private one, add it in the Argo CD UI under Settings, Repositories, with a personal access token.
2. In `argocd/applicationset.yaml`, replace `<your-github-user>` (twice), then commit and push.
3. Run `./setup.sh`. It prints the admin password at the end.
4. Start the UI with `kubectl port-forward -n argocd svc/argocd-server 8080:80` and open http://localhost:8080. Log in as `admin`.
5. Create the apps: `kubectl apply -f argocd/applicationset.yaml`. Three apps appear and sync within a minute.

## Demo script

Argo CD checks Git every 30 seconds in this setup. Click Refresh on an app to skip the wait.

**1. Deploy a code change.** In `apps/orders/values.yaml`, change `tag` from `6.5.0` to `6.6.0`, commit and push. This is what the pipeline will do for us. Watch demo-orders go OutOfSync, run the migrate Job, then roll out the new pod.

**2. See it running.** `kubectl port-forward -n demo-orders svc/orders 9898:9898`, then open http://localhost:9898. The page shows the version and the service's message.

**3. Change config without a build.** Change `message` in `apps/orders/values.yaml`, commit and push. Argo CD applies it; refresh the page from step 2 to see the new message.

**4. Manual change gets reverted.**

    kubectl -n demo-orders scale deploy orders --replicas=3

Within seconds Argo CD shows the drift and self-heal brings it back to 1 replica.

**5. Roll back.**

    git revert HEAD --no-edit && git push

The previous version comes back through a normal sync. Point out that the UI's Rollback button is disabled because auto-sync is on.

**6. Restart for a secret change.** In the app's resource tree, open the Deployment's menu and choose Restart. This is what you'll do after changing a Key Vault secret.

**7. CronJobs.** The `*-report` CronJobs appear in each tree; their Jobs and pods show up under them when they run.

## Clean up

    minikube delete -p argocd-demo
