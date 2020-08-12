# // VAULT_TOKEN ought to exist by now from either init or copy from vault1:
GLOBAL_LIMIT='3' ;

# // LB in front of Vault with X-Forwarded-For headers being sent:
vault write sys/quotas/rate-limit/global-rate rate=${GLOBAL_LIMIT} > /dev/null;
if (($? == 0)) ; then printf "VAULT: GLOBAL RATE LIMITING of ${GLOBAL_LIMIT} applied!.\n" ;
else printf 'VAULT ERROR: UNABLE TO APPLY GLOBAL RATE LIMITING.\n' ; fi ;

VAULT_AUDIT_PATH='vaudit.log' ;
vault audit enable file file_path=${VAULT_AUDIT_PATH} > /dev/null ;
if (($? == 0)) ; then printf "VAULT: Audit logs enabled at: ${VAULT_AUDIT_PATH}\n" ;
else printf 'VAULT ERROR: NOT ABLE TO ENABLE AUDITS.\n' ; fi ;

vault secrets enable -version=2 kv > /dev/null ;
if (($? == 0)) ; then printf "VAULT: Enabled KV secrets engine at: kv/\n" ;
else printf 'VAULT ERROR: NOT ABLE TO ENABLE KV secrets engine.\n' ; fi ;
