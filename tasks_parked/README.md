# Parked tasks

These tasks were consistently green (3/3 trials, many rounds) and carry no more
tuning signal, so they are parked here — **out of `run_all.sh`'s `tasks/*/` glob**
— to keep each Ralph round fast and focused on the tasks that still fail/flake.

Active tuning set lives in `tasks/`. As of parking: `17_bank_ledger`,
`18_txn_wal`, `21_sgf_parsing`, `26_flag_cleanup`.

## Re-activate a task

```bash
git mv tasks_parked/07_tdd_stack tasks/07_tdd_stack   # then re-baseline (restart ralph.sh)
```

Restart the loop after moving tasks so `ralph.sh` re-baselines its high-water
mark (`bar`) on the new set instead of decaying from the old one.
