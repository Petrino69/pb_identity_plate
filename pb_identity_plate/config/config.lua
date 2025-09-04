Config = {
    Locale = 'cs',

    -- ===== VIP změna jména =====
    vip = {
        item = 'vip_name_change',    -- item, kterým se změna jména provádí
        cooldownMinutes = 1440,      -- 24h cooldown mezi změnami jména
        blacklist = {                -- zakázaná slova (diakritika se ignoruje, case-insensitive)
            'admin','police','policie','server','owner','mod','staff','dev','fivem','nigger','kurva','kokot'
        },
        name = {
            minLen = 3,
            maxLen = 18,
            requireSpace = true,     -- vyžadovat mezery (jako jméno a příjmení)
            allowHyphen = true
        },
        requireVipAce = false,       -- pokud true, vyžaduje ACE group 'vip' (add_principal ... group.vip)
        discordLog = true
    },

    -- Jak aktualizovat jméno v ESX (vyber jednu metodu):
    identity = {
        mode = 'users_table',       -- 'esx_identity' (doporučeno) | 'users_table' | 'xplayer_setname'
        usersTableColumns = {        -- použije se jen pro mode='users_table'
            firstname = 'firstname',
            lastname  = 'lastname'
        }
    },

    -- ===== Sundání SPZ =====
    plates = {
        removeItem = 'plate_kit',    -- item pro sundání SPZ
        attachItem = 'plate_kit',        -- item pro opětovné připevnění SPZ (volitelné; nil = nevyžadovat)
        licensePlateItem = 'license_plate', -- item, který se dává do inventáře po sundání (s metadata)
        removedPlateText = 'ANON',       -- text, který se zobrazí místo SPZ (nesmí být prázdný, jinak může mizet kufr)
        durationMs = 8000,               -- doba „montáže/demontáže“
        skillcheck = false,              -- pokud máš lib.skillCheck, můžeš zapnout (true)
        engineMustBeOff = true,
        requireDriver = false,           -- už NENÍ potřeba, vše probíhá mimo vozidlo přes ox_target
        requireStopped = true,
        blockNearPolice = false,          -- když true, vyžaduje, aby v okolí nebyl policista (job v policeJobs)
        policeJobs = { 'police', 'sheriff' },
        show3DText = true,
        useTarget = true,                -- povolit ox_target interakce na SPZ
        discordLog = true
    },

    -- ===== Notifikace (okokNotify) =====
    notify = function(src, title, msg, type)
        -- type: 'success' | 'info' | 'warning' | 'error'
        TriggerClientEvent('okokNotify:Alert', src, title, msg, 5000, type)
    end,

    -- ===== Discord webhook log =====
    discordWebhook = '', -- doplň URL, jinak se logy neodesílají
}
