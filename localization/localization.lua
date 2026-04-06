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
    ---@class CharacterLocalization
    ---@field name localizationItem like "Reimu Hakurei"
    ---@field nickname localizationItem like "Shrine Maiden"
    characters = {
        REIMU = {
            name = {
                en_us = 'Reimu Hakurei',
                zh_cn = '博丽灵梦',
            },
            nickname = {
                en_us = 'Flying Shrine Maiden',
                zh_cn = '飞行的巫女',
            },
        },
        MARISA = {
            name = {
                en_us = 'Marisa Kirisame',
                zh_cn = '雾雨魔理沙',
            },
            nickname = {
                en_us = 'Ordinary Magician',
                zh_cn = '普通的魔法使',
            },
        },
        KOTOBA = {
            name = {
                en_us = 'Kotoba Kyokuwa',
                zh_cn = '曲话言波',
            },
            nickname = {
                en_us = 'Pun Materializer',
                zh_cn = '双关语具现者',
            },
        },
    },
    ui = {
        MAIN_MENU={
            FANGAME = {
                en_us = 'This is a Touhou fan game with no affiliation with ZUN or Team Shanghai Alice.',
                zh_cn = '这是一款东方Project同人游戏，与ZUN或上海爱丽丝幻乐团没有任何关系。',
            },
            DISCLAIMER = {
                en_us = 'Due to limitations of web browser, web version performs worse than downloaded versions. Some spellcards could be very laggy in the web version. Play the downloaded version for the best experience.',
                zh_cn = '由于网页浏览器的限制，网页版的性能不如下载版。某些符卡在网页版可能会非常卡顿。请下载游戏以获得最佳体验。',
            },
            GAME_START = {
                en_us = 'Game Start',
                zh_cn = '开始游戏',
            },
            EXTRA_START = {
                en_us = 'Extra Start',
                zh_cn = '额外开始',
            },
            PRACTICE = {
                en_us = 'Practice',
                zh_cn = '练习',
            },
            SPELL_PRACTICE = {
                en_us = 'Spell Practice',
                zh_cn = '符卡练习',
            },
            REPLAY = {
                en_us = 'Replay',
                zh_cn = '录像回放',
            },
            PLAYER_DATA = {
                en_us = 'Player Data',
                zh_cn = '游玩数据',
            },
            MUSIC_ROOM = {
                en_us = 'Music Room',
                zh_cn = '音乐室',
            },
            NICKNAMES = {
                en_us = 'Nicknames',
                zh_cn = '称号',
            },
            OPTIONS = {
                en_us = 'Options',
                zh_cn = '设置',
            },
            MANUAL = {
                en_us = 'Manual',
                zh_cn = '游戏说明',
            },
            EXIT = {
                en_us = 'Exit',
                zh_cn = '退出',
            },
        },
        OPTIONS={
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
        },
        CHOOSE_DIFFICULTY = {
            chooseDifficulty = {
                en_us = 'Choose Difficulty',
                zh_cn = '选择难度',
            },
            ---@class DifficultyDescriptionLocalization
            ---@field title localizationItem like "Flower Level", obscure first line
            ---@field plainName localizationItem like "EASY MODE", second line
            ---@field description localizationItem like "For beginners", third line
            
            ---@type table<DIFFICULTY, DifficultyDescriptionLocalization>
            difficultyDescriptions = {
                EASY = {
                    title = {
                        en_us = 'Lollipop Level',
                        zh_cn = '棒棒糖级',
                    },
                    plainName = {
                        en_us = 'EASY MODE',
                        zh_cn = 'EASY MODE',
                    },
                    description = {
                        en_us = 'A kid can lick this difficulty.',
                        zh_cn = '小孩子都能轻松应对的难度',
                    },
                },
                NORMAL = {
                    title = {
                        en_us = 'Rose Level',
                        zh_cn = '玫瑰级',
                    },
                    plainName = {
                        en_us = 'NORMAL MODE',
                        zh_cn = 'NORMAL MODE',
                    },
                    description = {
                        en_us = 'Beautiful and fragrant, but beware the hidden thorns.',
                        zh_cn = '娇艳欲滴的芬芳\n亦是暗藏锋芒的陷阱',
                    },
                },
                HARD = {
                    title = {
                        en_us = 'Firework Level',
                        zh_cn = '烟花级',
                    },
                    plainName = {
                        en_us = 'HARD MODE',
                        zh_cn = 'HARD MODE',
                    },
                    description = {
                        en_us = 'A momentary brilliance that dazzles the eyes and burns the skin.',
                        zh_cn = '瞬息的灿烂不仅夺人眼目\n更能灼伤肌肤',
                    },
                },
                LUNATIC = {
                    title = {
                        en_us = 'Rainbow Level',
                        zh_cn = '彩虹级',
                    },
                    plainName = {
                        en_us = 'LUNATIC MODE',
                        zh_cn = 'LUNATIC MODE',
                    },
                    description = {
                        en_us = 'You can never reach the end of the rainbow.',
                        zh_cn = '蝃蝀在东，莫之敢指',
                    },
                },
                EXTRA = {
                    title = {
                        en_us = 'Pearl Level',
                        zh_cn = '珍珠级',
                    },
                    plainName = {
                        en_us = 'EXTRA MODE',
                        zh_cn = 'EXTRA MODE',
                    },
                    description = {
                        en_us = 'A dream formed by pain, hidden at the center of the spiral.',
                        zh_cn = '磨砺痛苦而成的结晶\n深藏于螺旋之底的奢华',
                    },
                }
            }
        },
        CHOOSE_PLAYER = {
            choosePlayer = {
                en_us = 'Choose Player',
                zh_cn = '选择角色',
            },
            -- name and nickname are in characters section, so here we only need the descriptions for each player
            ---@type table<PLAYER, localizationItem>
            playerDescriptions={
                REIMU = {
                    en_us = 'Words say that an obscure beautiful place is accessible from the new travel hub. She raises an eyebrow and decides to investigate.',
                    zh_cn = '据说新的旅行枢纽通向一个隐蔽美丽的地方。她皱了皱眉，决定去调查一下。',
                },
                MARISA = {
                    en_us = 'She heard the news about the new travel hub and the mysterious place it can lead to. She is eager to check it out and loot some magical items.',
                    zh_cn = '据说新的旅行枢纽通向一个隐蔽美丽的地方。她很想去看看，顺便搜集一些魔法道具。',
                },
                KOTOBA = {
                    en_us = 'In the last incident, she accidentally created the "Hyperbolic Domain" and twisted the whole Gensokyo. The place becomes a travel hub and Reimu asks her to maintain it as compensation for the trouble. She hopes the rumored place can entertain her during the boring work.',
                    zh_cn = '在上次事件中，她意外创造的"双曲域"扭曲了整个幻想乡，之后变成一个旅行枢纽，灵梦要求她承担维护工作以补偿造成的麻烦。她希望传闻中的地方能作为无聊工作中的娱乐。',
                }
            },
            unfocusedShot = {
                en_us = 'Unfocused Shot',
                zh_cn = '高速射击',
            },
            focusedShot = {
                en_us = 'Focused Shot',
                zh_cn = '低速射击',
            },
            spellCard = {
                en_us = 'Spell Card',
                zh_cn = '符卡',
            },
            ---@class ShotTypeSubDescriptionLocalization
            ---@field title localizationItem like "Homing Amulet"
            ---@field description localizationItem like "A shot that automatically tracks enemies."

            ---@class ShotTypeDescriptionLocalization
            ---@field title localizationItem like "Homing Type"
            ---@field unfocusedShot ShotTypeSubDescriptionLocalization
            ---@field focusedShot ShotTypeSubDescriptionLocalization
            ---@field spellCard ShotTypeSubDescriptionLocalization

            ---@type table<SHOT_TYPE, ShotTypeDescriptionLocalization>
            shotTypeDescriptions={
                __default__ = {
                    title = {
                        en_us = 'Placeholder Type',
                        zh_cn = '占位类型',
                    },
                    __default__ = {
                        title = {
                            en_us = 'Not Decided Yet',
                            zh_cn = '尚未决定',
                        },
                        description = {
                            en_us = 'WIP :P',
                            zh_cn = '开发中 :P',
                        },
                    },
                }
            }
        },
        IN_GAME = {
            hiScore = {
                en_us = 'Hi-Score',
                zh_cn = '最高分',
            },
            score = {
                en_us = 'Score',
                zh_cn = '得分',
            },
            lives = {
                en_us = 'Lives',
                zh_cn = '残机',
            },
            bombs = {
                en_us = 'Bombs',
                zh_cn = '符卡',
            },
            grazes = {
                en_us = 'Grazes',
                zh_cn = '擦弹',
            }
        },

        -- below are from previous game
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
        title = {
            name = {
                en_us = 'Legend of Tokoyo',
                zh_cn = '常世国传说',
            },
            description = {
                en_us = 'The title screen theme.\nThe atmosphere is quite similar to Legend of Hourai: soft and nostalgic, like a storyteller begins to tell a tale of the past. The ending is already known, but they are still touched by the MC\'s resolution.',
                zh_cn = '标题画面的主题曲。\n氛围与《蓬莱传说》相似：柔和而怀旧，就像说书人开始讲一个过去的故事。结局已经为人所知，却仍被主角的愿望所感动。',
            },
        },
        level2b = {
            name = {
                en_us = 'Foxtrot Towards the Beyond',
                zh_cn = '通往远方的狐步舞',
            },
            description = {
                en_us = 'Tooshi Katsuyama\'s theme. (Currently also used as the title screen music)\nA playful and bouncy composition. The whole song keeps using similar rhythm patterns, but the switching of instruments and melodies makes it feel fresh and interesting the whole time. The fox gave herself a stoic name to mislead people (^^;',
                zh_cn = '堪山远志的主题曲。 (目前也用作标题画面的主题曲)\n一个有趣且弹跳的曲子。整首歌持续使用相似的节奏模式，但乐器和旋律的切换使曲子新鲜又有趣。狐狸给自己起了一个坚忍的名字来误导人们(^^;',
            },
        },
        level5 = {
            name = {
                en_us = 'Radio Signal Across the Ether',
                zh_cn = '穿越苍天的电波',
            },
            description = {
                en_us = 'Stage 5\'s theme.\nThe intro is repeated call and response, like sending and receiving radio signals. The title seems not related to the story? Just regard the flying protagonist as a radio signal (^^;',
                zh_cn = '5面的主题曲。\n前奏是重复的对唱，就像发送和接收无线电信号一样。这个曲名似乎与故事无关？就把飞行的主角当作无线电信号吧(^^;',
            }
        }
    },
    ---@type table<string, NicknameLocalization>
    nickname = {},
    dialogues = {},
}
