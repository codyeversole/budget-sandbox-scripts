echo Keycloak init starting...

for ARGUMENT in "$@"
do
        KEY=$(echo $ARGUMENT | cut -f1 -d=)

        KEY_LENGTH=${#KEY}
        VALUE="${ARGUMENT:$KEY_LENGTH+1}"

        export "$KEY"="$VALUE"
done

/opt/keycloak/bin/kcadm.sh config credentials --server https://login.budgetsandbox.com --realm master --user $keycloak_admin_username --password $keycloak_admin_password

/opt/keycloak/bin/kcadm.sh create realms -f - << EOF
{
        "realm" : "budgetsandbox",
        "enabled" : true,
        "displayName": "Budget Sandbox",
        "registrationAllowed": true,
        "registrationEmailAsUsername": false,
        "rememberMe": true,
        "verifyEmail": true,
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "resetPasswordAllowed": true,  
        "smtpServer": {
                "replyToDisplayName": "",
                "password" : "$keycloak_smtp_password",
                "starttls" : "true",
                "auth": "true",
                "port": "587",
                "host": "smtp.postmarkapp.com",
                "replyTo": "",
                "from": "support@budgetsandbox.com",
                "fromDisplayName": "Budget Sandbox",
                "envelopeFrom": "",
                "ssl": "false",
                "user" : "$keycloak_smtp_username"
        },
        "loginTheme": "budgetsandboxtheme"
}
EOF

/opt/keycloak/bin/kcadm.sh create clients -r budgetsandbox -f - << EOF
{
        "clientId" : "budget-sandbox-web-client",
        "enabled" : true,
        "redirectUris": ["https://budgetsandbox.com/*"],
        "webOrigins": ["https://budgetsandbox.com"],
        "standardFlowEnabled": true,
        "publicClient": true,
        "frontchannelLogout": true
}
EOF

/opt/keycloak/bin/kcadm.sh create clients -r budgetsandbox -f - << EOF
{
        "clientId" : "budget-sandbox-api-client",
        "enabled" : true,
        "clientAuthenticatorType" : "client-secret",
        "secret" : "$api_client_secret",
        "redirectUris" : [ "https://api.budgetsandbox.com/*" ],
        "webOrigins" : [ "https://api.budgetsandbox.com/*" ],
        "standardFlowEnabled" : false,
        "implicitFlowEnabled" : false,
        "directAccessGrantsEnabled" : false,
        "serviceAccountsEnabled" : true,
        "authorizationServicesEnabled" : true,
        "publicClient" : false,
        "frontchannelLogout" : true,
        "protocol" : "openid-connect",
        "attributes" : {
                "oidc.ciba.grant.enabled" : "false",
                "backchannel.logout.session.required" : "true",
                "post.logout.redirect.uris" : "+",
                "display.on.consent.screen" : "false",
                "oauth2.device.authorization.grant.enabled" : "false",
                "backchannel.logout.revoke.offline.tokens" : "false"
        }
}
EOF

/opt/keycloak/bin/kcadm.sh create roles -r budgetsandbox -s name=normal-user -s 'description=Regular user with a limited set of permissions'
/opt/keycloak/bin/kcadm.sh add-roles --rname default-roles-budgetsandbox --rolename normal-user -r budgetsandbox

/opt/keycloak/bin/kcadm.sh create users -r budgetsandbox -f - << EOF
{
        "username": "$test_user_username",
        "email": "$test_user_email",
        "emailVerified": true,
        "enabled": true,
        "credentials" : [ 
                {
                        "type": "password",
                        "temporary": false,
                        "value": "$test_user_password"
                }
        ],
        "realmRoles": [
                "default-roles-budgetsandbox"
        ]
}
EOF

echo Keycloak init finished!

exit