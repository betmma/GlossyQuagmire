---@alias lang string
---@alias localizationItem table<lang,string>
---@class obfuscationItem
---@field from string the characters to be replaced
---@field to string|nil the characters to replace with (randomly chosen), defaults to from
---@field toTable string[]|nil automatically generated (in misc.lua) table of characters in "to" string

---@alias obfuscationList obfuscationItem[]

return {
    levelData = {
    },
    ui = {
        DISCLAIMER = {
            en_us = 'Due to limitations of web browser, web version performs worse than downloaded versions. Some spellcards could be very laggy in the web version. Play the downloaded version for the best experience.',
            zh_cn = '由于网页浏览器的限制，网页版的性能不如下载版。某些符卡在网页版可能会非常卡顿。请下载游戏以获得最佳体验。',
        },
        START = {
            en_us = 'Start',
            zh_cn = '开始游戏',
        },
        REPLAY = {
            en_us = 'Replay',
            zh_cn = '录像回放',
        },
        OPTIONS = {
            en_us = 'Options',
            zh_cn = '设置',
        },
        MUSIC_ROOM = {
            en_us = 'Music Room',
            zh_cn = '音乐室',
        },
        NICKNAMES = {
            en_us = 'Nicknames',
            zh_cn = '称号',
        },
        EXIT = {
            en_us = 'Exit',
            zh_cn = '退出',
        },
        NEXT_SCENE = {
            en_us = 'Next Scene',
            zh_cn = '下一场景',
        },
        RESTART = {
            en_us = 'Restart',
            zh_cn = '重新开始',
        },
        SAVE_REPLAY = {
            en_us = 'Save Replay',
            zh_cn = '保存录像',
        },
        RESUME = {
            en_us = 'Resume',
            zh_cn = '继续',
        },
        master_volume = {
            en_us = 'Master Volume',
            zh_cn = '主音量',
        },
        music_volume = {
            en_us = 'Music Volume',
            zh_cn = '音乐音量',
        },
        sfx_volume = {
            en_us = 'SFX Volume',
            zh_cn = '音效音量',
        },
        language = {
            en_us = 'Language',
            zh_cn = '语言',
        },
        resolution = {
            en_us = 'Resolution',
            zh_cn = '分辨率',
        },
        playTimeOverall = {
            en_us = 'Playtime Overall:\n{playtime}',
            zh_cn = '总游戏时间: {playtime}',
        },
        playTimeInLevel = {
            en_us = 'Playtime in levels:\n{playtime}',
            zh_cn = '关卡内游戏时间: {playtime}',
        },
        levelUIHint = {
            en_us = 'C: Upgrades Menu',
            zh_cn = 'C: 升级菜单',
        },
        playerHP = {
            en_us = 'HP: {HP}',
            zh_cn = '生命值: {HP}',
        },
        paused = {
            en_us = 'Paused',
            zh_cn = '已暂停',
        },
        win = {
            en_us = 'You win!',
            zh_cn = '挑战成功',
        },
        lose = {
            en_us = 'You lose!',
            zh_cn = '满身疮痍',
        },
        timeout = { -- the spell card type is timeout
            en_us = 'T I M E O U T',
            zh_cn = '耐 久',
        },
        replaying = {
            en_us = 'Replaying',
            zh_cn = '回放中',
        },
        nicknameGet = {
            en_us = 'Get nickname:',
            zh_cn = '获得称号:',
        },
        replayDigitsEntered = {
            en_us = 'Digits entered: {digits}',
            zh_cn = '已输入数字: {digits}',
        },
        hyperbolicModels = {
            model = {
                en_us = 'Model: ',
                zh_cn = '模型: ',
            },
            HalfPlane = {
                en_us = 'Half-Plane',
                zh_cn = '半平面',
            },
            PoincareDisk = {
                en_us = 'Poincaré Disk',
                zh_cn = '庞加莱圆盘',
            },
            KleinDisk = {
                en_us = 'Klein Disk',
                zh_cn = '克莱因圆盘',
            },
        },
        secretNicknameSuffix = {
            en_us = ' (secret)',
            zh_cn = '（隐藏）',
        },
    },
    notice = {

    },
    musicData = {
        unknown = {
            name = {
                en_us = '???????????????????',
                zh_cn = '？？？？？？？？？？？？',
            },
            description = {
                en_us = 'You have not met this music yet.',
                zh_cn = '你还没有遇到这首音乐。',
            },
        },
        level2b = {
            name = {
                en_us = 'test',
                zh_cn = 'test',
            },
            description = {
                en_us = 'This is a test music.',
                zh_cn = '这是测试音乐。',
            },
        },
    },
    ---@type table<string, NicknameLocalization>
    nickname = {},
    dialogues = {},
}
