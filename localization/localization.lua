---@alias lang string
---@alias magicString string -- defined in misc.getRawLocalizeString. something like '@op:val' that can be used to refer to other localization items or do some operations. currently only supports '@ref:someKey' to refer to other localization items in the same table to avoid repetition.
---@alias localizationItem table<lang,string>

return {
    ---@class spellcardLocalizationUnit:strict
    ---@field name localizationItem
    ---@class spellcardLocalization:strict
    ---@field __default__? spellcardLocalizationUnit
    ---@field [DIFFICULTY] spellcardLocalizationUnit|magicString
    ---@type table<string, spellcardLocalization>
    spellcards={
        UNKNOWN = {
            __default__ = {
                name = {
                    en_us = 'Unknown Spellcard',
                    zh_cn = '未知符卡',
                },
            },
        },
        test = {
            __default__ = {
                name = {
                    en_us = 'Test Spellcard',
                    zh_cn = '测试符卡',
                },
            },
        },
        ['kotoba-swallow'] = {
            EASY = {
                name = {
                    en_us = 'Swallow Sign "Death of the Clumsy Birds"',
                    zh_cn = '吞燕「拙燕之死」',
                },
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Swallow Sign "Death of the Black Wings"',
                    zh_cn = '吞燕「玄鸟之死」',
                },
            },
        },
        ['kotoba-pupil'] = {
            EASY = {
                name = {
                    en_us = 'Pupil Sign "Gazes of the Students"',
                    zh_cn = '神瞳「目光如炬」',
                },
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Pupil Sign "Gazes of the Disciples"',
                    zh_cn = '神瞳「目光如电」',
                }
            }
        },
        ['kotoba-lead'] = {
            __default__ = {
                name = {
                    en_us = 'Lead Sign "Follow the Heavy Signs"',
                    zh_cn = '铅制「沉重路标」',
                },
            }
        },
        ['reimu-dream-seal'] = {
            __default__ = {
                name = {
                    en_us = 'Spirit Sign "Dream Seal -Concentrate-"',
                    zh_cn = '灵符「梦想封印　集」',
                }
            }
        },
        ['marisa-star'] = {
            EASY = {
                name = {
                    en_us = 'Star Sign "\'Oumuamua"',
                    zh_cn = '星符「奥陌陌」',
                }
            },
            NORMAL = {
                name = {
                    en_us = 'Star Sign "\'Ayló\'chaxnim"',
                    zh_cn = '星符「爱洛查赫妮姆」',
                }
            },
            HARD = {
                name = {
                    en_us = 'Star Sign "G!ò\'é !Hú"',
                    zh_cn = '星符「雹卫一」',
                }
            },
            __default__ = {
                name = {
                    en_us = 'Star Sign "G!kún||\'hòmdímà"',
                    zh_cn = '星符「雹神星」',
                }
            },
        },
        ['marisa-light'] = {
            EASY = {
                name = {
                    en_us = 'Light Sign "Rainbow Wave"',
                    zh_cn = '光符「彩虹波」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Light Blast "Chroma Swirl"',
                    zh_cn = '光击「色彩漩涡」',
                }
            }
        }
    },
    levelData = {
    },
    ---@class CharacterLocalization
    ---@field name localizationItem like "Reimu Hakurei"
    ---@field nickname localizationItem like "Shrine Maiden"
    characters = {
        __default__ = {
            name = {
                en_us = 'Unknown Character',
                zh_cn = '未知角色',
            },
            nickname = {
                en_us = 'Unknown Nickname',
                zh_cn = '未知称号',
            },
        },
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
        kotoba = '@ref:KOTOBA', -- player names are uppercase, boss and dialogue names are lowercase
        reimu = '@ref:REIMU',
        marisa = '@ref:MARISA',
    },
    ui = {
        MAIN_MENU={
            FANGAME = {
                en_us = 'This is a Touhou fan game with no affiliation with ZUN or Team Shanghai Alice.',
                zh_cn = '这是一款东方Project同人游戏，与ZUN或上海爱丽丝幻乐团没有任何关系。',
            },
            DISCLAIMER = {
                en_us = 'Due to limitations of web browser, web version performs worse than downloaded versions. Some parts could be very laggy in the web version. Play the downloaded version for the best experience.',
                zh_cn = '由于网页浏览器的限制，网页版的性能不如下载版。某些地方在网页版可能会非常卡顿。请下载游戏以获得最佳体验。',
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
                },
                REIMUA = {
                    title = {
                        en_us = 'Homing Type',
                        zh_cn = '追踪型',
                    },
                    unfocusedShot = {
                        title = {
                            en_us = 'Sealing Needle',
                            zh_cn = '封魔针',
                        },
                        description = {
                            en_us = 'Forward shot',
                            zh_cn = '前方射击',
                        },
                    },
                    focusedShot = {
                        title = {
                            en_us = 'Homing Amulet',
                            zh_cn = '追踪符札',
                        },
                        description = {
                            en_us = 'Automatically tracks enemies',
                            zh_cn = '自动追踪敌人',
                        },
                    },
                    spellCard = {
                        title = {
                            en_us = 'Spirit Sign "Fantasy Amulet"',
                            zh_cn = '灵符「梦想符札」',
                        },
                        description = {
                            en_us = 'Huge amulet with mystery pattern',
                            zh_cn = '有着神秘图案的巨大符札',
                        },
                    }
                },
                REIMUB = {
                    title = {
                        en_us = 'Wide Type',
                        zh_cn = '广范围型',
                    },
                    unfocusedShot = {
                        title = {
                            en_us = 'Big Amulet',
                            zh_cn = '巨大符札',
                        },
                        description = {
                            en_us = 'Wide shot',
                            zh_cn = '广范围射击',
                        },
                    },
                    focusedShot = {
                        title = {
                            en_us = 'Big Amulet',
                            zh_cn = '巨大符札',
                        },
                        description = {
                            en_us = 'Forward shot',
                            zh_cn = '前方射击',
                        },
                    },
                    spellCard = {
                        title = {
                            en_us = 'Spirit Sign "Fantasy Amulet"',
                            zh_cn = '灵符「梦想符札」',
                        },
                        description = {
                            en_us = 'Huge amulet with mystery pattern',
                            zh_cn = '有着神秘图案的巨大符札',
                        },
                    }
                },
                MARISAA = {
                    title = {
                        en_us = 'High Power Type',
                        zh_cn = '高威力型',
                    },
                    focusedShot = {
                        title = {
                            en_us = 'Illusion Laser',
                            zh_cn = '幻影激光',
                        },
                        description = {
                            en_us = 'Converging forward',
                            zh_cn = '前方汇聚',
                        }
                    },
                    unfocusedShot = {
                        title = {
                            en_us = 'Refraction Laser',
                            zh_cn = '折射激光',
                        },
                        description = {
                            en_us = 'Branching shot',
                            zh_cn = '分叉攻击',
                        }
                    },
                    spellCard = {
                        title = {
                            en_us = 'Star Sign "Meteor Spark"',
                            zh_cn = '星符「流星火花」',
                        },
                        description = {
                            en_us = 'Many piercing stars',
                            zh_cn = '许多能穿透的星星',
                        },
                    },
                },
                MARISAB = {
                    title = {
                        en_us = 'All-Around Type',
                        zh_cn = '全方位型',
                    },
                    focusedShot = {
                        title = {
                            en_us = 'Comet Burst',
                            zh_cn = '彗星爆弹',
                        },
                        description = {
                            en_us = 'Forward wide shot',
                            zh_cn = '前方广范围射击',
                        }
                    },
                    unfocusedShot = {
                        title = {
                            en_us = 'Nebula Burst',
                            zh_cn = '星云爆弹',
                        },
                        description = {
                            en_us = 'All-Around shot',
                            zh_cn = '全方位射击',
                        }
                    },
                    spellCard = {
                        title = {
                            en_us = 'Star Sign "Meteor Spark"',
                            zh_cn = '星符「流星火花」',
                        },
                        description = {
                            en_us = 'Many piercing stars',
                            zh_cn = '许多能穿透的星星',
                        },
                    },
                },
                KOTOBAA = {
                    title = {
                        en_us = 'Poker Type',
                        zh_cn = '扑克型',
                    },
                    focusedShot = {
                        title = {
                            en_us = 'Straight Flush',
                            zh_cn = '顺子',
                        },
                        description = {
                            en_us = 'Straight Shot',
                            zh_cn = '……克敌制胜',
                        }
                    },
                    unfocusedShot = {
                        title = {
                            en_us = 'Wild Card',
                            zh_cn = '散牌',
                        },
                        description = {
                            en_us = 'Wide Shot',
                            zh_cn = '扑向目标……',
                        }
                    },
                    spellCard = {
                        title = {
                            en_us = '"Hyper Ball"',
                            zh_cn = '「超球」',
                        },
                        description = {
                            en_us = 'Reflect enemy bullets',
                            zh_cn = '反射敌方子弹',
                        },
                    }
                },
                KOTOBAB = {
                    title = {
                        en_us = 'Stationery Type',
                        zh_cn = '纸型',
                    },
                    focusedShot = {
                        title = {
                            en_us = 'Paper Plane',
                            zh_cn = '纸飞机',
                        },
                        description = {
                            en_us = 'Stationary then flying straight',
                            zh_cn = '止直至掷',
                        }
                    },
                    unfocusedShot = {
                        title = {
                            en_us = 'Sticky Note',
                            zh_cn = '便签纸',
                        },
                        description = {
                            en_us = 'Flying then stationary',
                            zh_cn = '掷直至止',
                        }
                    },
                    spellCard = {
                        title = {
                            en_us = '"Hyper Ball"',
                            zh_cn = '「超球」',
                        },
                        description = {
                            en_us = 'Reflect enemy bullets',
                            zh_cn = '反射敌方子弹',
                        },
                    }
                }
            }
        },
        IN_GAME = {
            ---@class StageTitleLocalization
            ---@field main localizationItem
            ---@field small localizationItem
            ---@type table<StageKey, StageTitleLocalization>
            STAGE_TITLE = {
                stage1 = {
                    main = {
                        en_us = 'Twisted Twig',
                        zh_cn = '纠葛的枝梢',
                    },
                    small = {
                        en_us = 'STAGE 1   Hyperbolic Domain',
                        zh_cn = 'STAGE 1   双曲域',
                    }
                },
                stage2 = {
                    main = {
                        en_us = 'Scurrying in the Gorge',
                        zh_cn = '疾走于绝壁之间',
                    },
                    small = {
                        en_us = 'STAGE 2   Secret Path',
                        zh_cn = 'STAGE 2   秘密道路',
                    }
                }
            },
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
            power = {
                en_us = 'Power',
                zh_cn = '火力',
            },
            grazes = {
                en_us = 'Grazes',
                zh_cn = '擦弹',
            },
            bgm = {
                en_us = 'BGM: {bgm}', -- this font doesnt have the eighth note symbol
                zh_cn = '♪ {bgm}',
            },
            replaying = {
                en_us = 'Replaying',
                zh_cn = '回放中',
            },
            ---@enum (key) NoticeKey
            notices = {
                getSpellCardBonus = {
                    en_us = 'Get Spell Card Bonus!!',
                    zh_cn = '获得符卡奖励！！',
                },
                spellCardBonusFailed = {
                    en_us = 'Bonus Failed...',
                    zh_cn = '奖励失败……',
                },
                challengeNextStage = {
                    en_us = 'Challenge Next Stage!',
                    zh_cn = '挑战下一关！',
                },
                fullPowerUp = {
                    en_us = 'Full Power-Up!',
                    zh_cn = '火力全开！',
                },
                hiscore = {
                    en_us = 'Hi-Score!',
                    zh_cn = '新高分！',
                },
                extend = {
                    en_us = 'Extend!!',
                    zh_cn = '获得残机！！',
                },
            }
        },
        SPELL_PRACTICE = {
            ---@type table<StageKey, localizationItem>
            stages = {
                stage1 = {
                    en_us = 'Stage 1',
                    zh_cn = '一面',
                },
                stage2 = {
                    en_us = 'Stage 2',
                    zh_cn = '二面',
                },
                stage3 = {
                    en_us = 'Stage 3',
                    zh_cn = '三面',
                },
                stage4 = {
                    en_us = 'Stage 4',
                    zh_cn = '四面',
                },
                stage5 = {
                    en_us = 'Stage 5',
                    zh_cn = '五面',
                },
                stage6 = {
                    en_us = 'Stage 6',
                    zh_cn = '六面',
                },
                stageEX = {
                    en_us = 'Stage EX',
                    zh_cn = 'EX面',
                },
            },
            cursor = {
                back = {
                    en_us = 'BACK',
                    zh_cn = '返回',
                },
                start = {
                    en_us = 'START',
                    zh_cn = '开始',
                },
            },
            spellcard = {
                en_us = 'Spellcard {index}',
                zh_cn = '符卡 {index}',
            },
            spellcardHistory = {
                en_us = 'IN GAME {ingamePass}/{ingameTries} PRACTICE {practicePass}/{practiceTries}',
                zh_cn = '实战 {ingamePass}/{ingameTries} 练习 {practicePass}/{practiceTries}',
            },
            ---@type table<SHOT_TYPE, localizationItem>
            shotTypes = {
                REIMUA = {
                    en_us = 'Reimu A',
                    zh_cn = '灵梦A',
                },
                REIMUB = {
                    en_us = 'Reimu B',
                    zh_cn = '灵梦B',
                },
                MARISAA = {
                    en_us = 'Marisa A',
                    zh_cn = '魔理沙A',
                },
                MARISAB = {
                    en_us = 'Marisa B',
                    zh_cn = '魔理沙B',
                },
                KOTOBAA = {
                    en_us = 'Kotoba A',
                    zh_cn = '言波A',
                },
                KOTOBAB = {
                    en_us = 'Kotoba B',
                    zh_cn = '言波B',
                },
            }
        },
        PAUSE = {
            paused = {
                en_us = 'Paused',
                zh_cn = '已暂停',
            },
            resume = {
                en_us = 'Resume',
                zh_cn = '继续游戏',
            },
            restart = {
                en_us = 'Restart',
                zh_cn = '重新开始'
            },
            exit = {
                en_us = 'Exit',
                zh_cn = '退出游戏'
            }
        },
        GAME_END = {
            failed = {
                en_us = 'Devastated',
                zh_cn = '满身疮痍'
            },
            cleared = {
                en_us = 'Cleared',
                zh_cn = '成功通关'
            },
            replayEnd = {
                en_us = 'Replay End',
                zh_cn = '录像结束'
            },
            practiceEnd = {
                en_us = 'Practice End',
                zh_cn = '练习结束'
            },
            saveReplay = {
                __default__= {
                    en_us = 'Save Replay',
                    zh_cn = '保存录像'
                },
            },
            restart = {
                normal = {
                    en_us = 'Try Again',
                    zh_cn = '重新开始'
                },
                playingReplay = {
                    en_us = 'Watch Again',
                    zh_cn = '再看一遍'
                }
            },
            exit = {
                __default__= {
                    en_us = 'Exit',
                    zh_cn = '退出'
                }
            }
        },
        SAVE_REPLAY_ENTER_NAME={
            enterName = {
                en_us = 'Enter Name',
                zh_cn = '输入名字'
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
        level1 = {
            name = {
                en_us = 'Electronic Hub',
                zh_cn = '短路旅行枢纽',
            },
            description = {
                en_us = 'Stage 1\'s theme.\nSimple pentatonic melodies. Energetic feeling in the beginning of the journey. The Hyperbolic Domain is too electronic because Kotoba thought of the networking meaning of "hub" (^^;',
                zh_cn = '第一面的主题曲。\n简单的五声调式旋律。旅途开始时的活力。双曲域过于电子工程化了，这是因为言波想到了“短路”的双关含义。听上去很危险呢(^^;'
            }
        },
        level1b = {
            name = {
                en_us = 'Materialized Malapropism',
                zh_cn = '具现飞白'
            },
            description = {
                en_us = 'Kotoba Kyokuwa\'s theme.\nUnnecessarily rapid and dark for stage 1 huh? If this trend continues, player would be exhausted before facing the real challenges.',
                zh_cn = '曲话言波的主题曲。\n用于一面，是不是过于快速和黑暗了？如果继续这样下去，玩家在面对真正的挑战之前就会精疲力尽了吧。'
            }
        },
        level1c = {
            name = {
                en_us = 'Unrestrained Magic ~ Eastern Magician',
                zh_cn = '奔放的魔法　～ Eastern Magician',
            },
            description = {
                en_us = 'Marisa Kirisame\'s theme.\nVery emotional. When writing the intro I was thinking of her IN theme\'s intro, but later I found I mistook Reimu\'s intro for hers. It still makes sense, because Reimu is the midboss and deserves a part (^^;',
                zh_cn = '雾雨魔理沙的主题曲。\n很有感情。在写前奏时，我原本想着她永夜抄主题曲的前奏，但后来发现把灵梦的前奏误认为是她的了。也可以吧，因为灵梦是道中Boss，值得有一段 (^^;',
            }
        },
        level2b = {
            name = {
                en_us = 'Foxtrot Towards the Beyond',
                zh_cn = '通往远方的狐步舞',
            },
            description = {
                en_us = 'Tooshi Katsuyama\'s theme. (Planned Stage 2 boss\'s theme)\nA playful and bouncy composition. The whole song keeps using similar rhythm patterns, but the switching of instruments and melodies makes it feel fresh and interesting the whole time. The fox gave herself a stoic name to mislead people (^^;',
                zh_cn = '堪山远志的主题曲。 (计划为2面BOSS的主题曲)\n一个有趣且弹跳的曲子。整首歌持续使用相似的节奏模式，但乐器和旋律的切换使曲子新鲜又有趣。狐狸给自己起了一个坚忍的名字来误导人们(^^;',
            },
        },
        level5 = {
            name = {
                en_us = 'Radio Signal Across the Ether',
                zh_cn = '穿越苍天的电波',
            },
            description = {
                en_us = 'Stage 5\'s theme.\nThe intro is repeated call and response, like sending and receiving radio signals. The title seems not related to the story? Just regard the flying protagonist as a radio signal (^^;',
                zh_cn = '第五面的主题曲。\n前奏是重复的对唱，就像发送和接收无线电信号一样。这个曲名似乎与故事无关？就把飞行的主角当作无线电信号吧(^^;',
            }
        }
    },
    ---@type table<string, NicknameLocalization>
    nickname = {},
    dialogues = {
        REIMUS1BossBefore = {
            hiKotoba = {
                en_us = 'Hi Kotoba!',
                zh_cn = '嗨，言波！',
            },
            howsYourWorkHere = {
                en_us = 'How\'s your work here?',
                zh_cn = '你在这工作，感觉怎么样呀？',
            },
            workIsFine = {
                en_us = 'Work is fine.',
                zh_cn = '工作还行。',
            },
            haveYouHeardThatMysteriousPlace = {
                en_us = 'Have you heard about that mysterious place that can be accessed from this travel hub?',
                zh_cn = '你听说过那个可以从这里进入的神秘地方吗？',
            },
            ughNo = {
                en_us = 'Ugh, no. (She knows I\'ll leave work early to check that place?)',
                zh_cn = '呃，没有。(她知道我会早退去那个地方？)',
            },
            howCanYouNotKnow = {
                en_us = 'How can you not know about it? That would be a safety issue if you, the manager of here, don\'t know about it.',
                zh_cn = '你怎么能不知道？如果你身为管理员都不知道的话，那可就是安全问题了。',
            },
            ahhhIMeanIKnowBut = {
                en_us = 'Ahhh! I mean, I have heard about it but don\'t quite remember...',
                zh_cn = '啊啊！我是说，我听说过，但不太记得了……',
            },
            aDanmakuBattleWouldHelpYouRemember = {
                en_us = 'A danmaku battle would help you remember, right?',
                zh_cn = '打一场弹幕战会帮助你回忆起来的，对吧？',
            }
        },
        REIMUS1BossAfter = {
            yeahIRememberNow = {
                en_us = 'Yeah, I remember now.',
                zh_cn = '嗯，我现在记起来了。',
            },
            soItsThisWay = {
                en_us = 'So it\'s this way. Bye.',
                zh_cn = '所以是这条路。拜拜。',
            }
        },
        MARISAS1BossBefore = {
            wowThisPlaceSoCool = {
                en_us = 'Wow, this place is sick!',
                zh_cn = '哇，这个地方太棒了！',
            },
            welcomeToHyperbolicDomain = {
                en_us = 'Welcome to the Hyperbolic Domain, the travel hub of Gensokyo!',
                zh_cn = '欢迎来到双曲域，幻想乡的交通枢纽！',
            },
            ohHi = {
                en_us = 'Oh hi...',
                zh_cn = '哦嗨……',
            },
            wheresThatPlace = {
                en_us = 'Where\'s that place? Squinting my eyes...',
                zh_cn = '那个地方在哪里？眯着眼睛找找……',
            },
            waitThatThievishLook = {
                en_us = 'Wait, that thievish look... What are you planning?',
                zh_cn = '等等，这贼眉鼠眼的表情……你在打什么主意？',
            },
            iMustStopYouNow = {
                en_us = 'I must stop you now!',
                zh_cn = '我必须阻止你了！',
            }
        },
        MARISAS1BossAfter = {
            youreStrong = {
                en_us = 'You\'re strong...',
                zh_cn = '好强……',
            },
            ofCourseIAm = {
                en_us = 'Of course I am. Ha!',
                zh_cn = '那当然了。哈哈！',
            },
            whatAreYouLookingForHere = {
                en_us = 'So what are you looking for here?',
                zh_cn = '所以你在这里找什么？',
            },
            thatPlace = {
                en_us = 'That place that can be accessed from this travel hub. I heard it\'s really cool!',
                zh_cn = '那个可以从双曲域进入的地方。我听说那里很棒！',
            },
            thisWay = {
                en_us = 'It\'s this way. See the sign on the wall?',
                zh_cn = '就在这条路上。看到墙上的标志了吗？',
            },
            shouldTellMeInTheBeginning = {
                en_us = 'You should tell me in the beginning, you know?',
                zh_cn = '你应该一开始就告诉我的，知道吧？',
            }
        },
        KOTOBAS1BossBefore = {
            wheresThatPlace = {
                en_us = 'Where\'s that place? Squinting my eyes...',
                zh_cn = '那个地方在哪里？眯着眼睛找找……',
            },
            waitThatThievishLook = {
                en_us = 'Wait, that thievish look... What is she planning?',
                zh_cn = '等等，这贼眉鼠眼的表情……她在打什么主意？',
            },
            whoYouAre = {
                en_us = 'Who are you? What are you doing now?',
                zh_cn = '你是谁？你在做什么？',
            },
            imReimu = {
                en_us = 'I\'m Reimu Hakurei. The shrine maiden.',
                zh_cn = '我是博丽灵梦。那个巫女。',
            },
            iJustMetHerYouKnow = {
                en_us = 'I just met her one minute ago. She dresses in red, you know?',
                zh_cn = '我一分钟前刚见过她。她穿红色的，知道吧？',
            },
            herDressCanChangeColorYouKnow = {
                en_us = 'Her dress can change color, you know? That infrared fabric...',
                zh_cn = '她的裙子会变色的，知道吧？红外线编出来的！',
            },
            thatsLame = {
                en_us = 'Infrared fabric? No, that\'s entirely fabricated!',
                zh_cn = '红外线编的？不会编就别编了！',
            },
            okthenImMarisa = {
                en_us = 'Ok then, I\'m Marisa Kirisame!',
                zh_cn = '那好吧，我是雾雨魔理沙！',
            },
            andIllPunishYou = {
                en_us = 'And I\'ll punish you right now!',
                zh_cn = '我现在就惩罚你！',
            }
        },
        KOTOBAS1BossAfter = {
            impossible = {
                en_us = 'Impossible... How could you defeat me?',
                zh_cn = '不可能……你怎么能打败我？',
            },
            whatStrangePerson = {
                en_us = 'What a strange person...',
                zh_cn = '真是个奇怪的人……',
            }
        },
        S2Branch1 = {
            hiThere = {
                en_us = 'Hi there.',
                zh_cn = '嗨，你好呀。',
            },
            areYouGoingForward = {
                en_us = 'Are you going forward? I can lead you.',
                zh_cn = '你要往前走吗？我可以带路哦。',
            },
            thereAreTwoPaths = {
                en_us = 'There are two paths ahead. The left one is safer, while the right one has more rewards.',
                zh_cn = '前面有两条路。左边的路更安全，右边的路奖励更多。',
            },
            stayAtLeftOrRightSide = {
                en_us = 'Stay at the left or right side of the screen to choose.',
                zh_cn = '待在屏幕左侧或右侧来选择。',
            },
            three = {
                en_us = 'Three...',
                zh_cn = '三……',
            },
            two = {
                en_us = 'Two...',
                zh_cn = '二……',
            },
            one = {
                en_us = 'One...',
                zh_cn = '一……',
            }
        },
        S2BranchLeft = {
            youChoseLeft = {
                en_us = 'The safer path? Ok, follow me!',
                zh_cn = '安全的道路？好的，跟我来！',
            },
        },
        S2BranchRight = {
            youChoseRight = {
                en_us = 'The more rewarding path? Ok, Follow me!',
                zh_cn = '奖励更多的道路？好的，跟我来！',
            },
        },
    },
}
