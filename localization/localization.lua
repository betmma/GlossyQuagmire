---@alias lang string
---@alias magicString string -- defined in misc.getRawLocalizeString. something like '@op:val' that can be used to refer to other localization items or do some operations. currently supports '@ref:someKey' to refer to other localization items in the same table to avoid repetition, and '@nolocalize:layer' to return the raw value (no layer or layer=0) or certain previous layer (like localize('a','b','c') with .a.b.c='@nolocalize:1' would refer to 1 layer above that is 'b').
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
        },
        ['tooshi-dance'] = {
            EASY = {
                name = {
                    en_us = 'Dance Sign "Fox Steps"',
                    zh_cn = '舞符「狐之舞步」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Dance Sign "Illusional Fox Steps"',
                    zh_cn = '舞符「幻影狐步」',
                }
            }
        },
        ['tooshi-lantern'] = {
            EASY = {
                name = {
                    en_us = 'Bright Lantern "Light that Guides You"',
                    zh_cn = '明灯「指引前路之光」',
                }
            },
            NORMAL = {
                name = {
                    en_us = 'Bright Lantern "Light that Soothes You"',
                    zh_cn = '明灯「抚慰心灵之光」',
                }
            },
            HARD = {
                name = {
                    en_us = 'Bright Lantern "Light that is Immaculate and Solemn"',
                    zh_cn = '明灯「无垢庄严之光」',
                }
            },
            __default__ = {
                name = {
                    en_us = 'Bright Lantern "Light that Eliminates Darkness"',
                    zh_cn = '明灯「灭除痴暗之光」',
                }
            }
        },
        ['tooshi-flower'] = {
            __default__ = {
                name = {
                    en_us = 'Flower Sign "Quiet in Purple"',
                    zh_cn = '花符「紫色的沉静」',
                }
            }
        },
        ['kora-cosmos'] = {
            EASY = {
                name = {
                    en_us = 'Reflection Sign "Colorful Daisy"',
                    zh_cn = '映符「多彩雏菊」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Reflected Flower "Colorful Cosmos"',
                    zh_cn = '映花「多彩波斯菊」',
                }
            }
        },
        ['kora-manifest'] = {
            EASY = {
                name = {
                    en_us = 'Manifest Sign "Reveal the Spirits"',
                    zh_cn = '显现「照妖镜」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Manifest Sign "Reveal the True Colors"',
                    zh_cn = '显现「魍魉现形」',
                }
            },
        },
        ['kora-self'] = {
            EASY = {
                name = {
                    en_us = 'Self Sign "Self Reflection"',
                    zh_cn = '自我「自我映照」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Self Sign "Narcissistic Personality"',
                    zh_cn = '自我「自恋人格」',
                }
            },
        },
        ['kora-tear'] = {
            EASY = {
                name = {
                    en_us = 'Tear Sign "Broken Screen"',
                    zh_cn = '撕裂「破碎的屏幕」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Tear Sign "Hole in the Mirror"',
                    zh_cn = '撕裂「镜中的洞」',
                }
            },
        },
        ['kora-world'] = {
            __default__ = {
                name = {
                    en_us = '"World of Trinity"',
                    zh_cn = '「三生万物的世界」',
                }
            },
        },
        ['shouji-bridge'] = {
            EASY = {
                name = {
                    en_us = 'Cross Sign "The Floating Bridge of Heaven"',
                    zh_cn = '渡符「天浮桥」',
                }
            },
            NORMAL = {
                name = {
                    en_us = 'Judgement "The Chinvat Bridge"',
                    zh_cn = '审判「钦瓦特桥」',
                }
            },
            HARD = {
                name = {
                    en_us = 'Vision "The Vision of Adamnan"',
                    zh_cn = '启示「阿当南的异象」',
                }
            },
            __default__ = {
                name = {
                    en_us = 'Purgatory "The Brig o\' Dread"',
                    zh_cn = '譬喻「二河白道」',
                }
            },
        },
        ['shouji-trick'] = {
            __default__ = {
                name = {
                    en_us = 'Trick "Through the Revolving Trapdoor"',
                    zh_cn = '技法「机关门的背后」',
                }
            },
        },
        ['shouji-life'] = {
            __default__ = {
                name = {
                    en_us = 'Life Gate "Red Apricot Out of the Wall"',
                    zh_cn = '生门「红杏出墙」',
                }
            }
        },
        ['shouji-death'] = {
            __default__ = {
                name = {
                    en_us = 'Death Gate "Final Nails in the Coffin"',
                    zh_cn = '死门「最后的棺材钉」',
                }
            }
        },
        ['shouji-scenery'] = {
            EASY = {
                name = {
                    en_us = 'Scenery Gate "Intertwined Red Ropes"',
                    zh_cn = '景门「交织的红绳」',
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Scenery Gate "The Red Thread of Fate"',
                    zh_cn = '景门「命运的红线」',
                }
            }
        },
        ['shouji-fear'] = {
            __default__ = {
                name = {
                    en_us = 'Fear Gate "Scraping Dragon\'s Reverse Scales"',
                    zh_cn = '惊门「批逆龙鳞」',
                }
            },
        },
        ['shouji-rest'] = {
            EASY = {
                name = {
                    en_us = 'Rest Gate "Water Ripples"',
                    zh_cn = '休门「水波纹」'
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Rest Gate "Black Turtle-Snake Pattern"',
                    zh_cn = '休门「玄武纹」',
                }
            }
        },
        ['shouji-block'] = {
            EASY = {
                name = {
                    en_us = 'Block Gate "Puzzle Boxes of Boxwood and Silver Birch"',
                    zh_cn = '杜门「黄杨与白桦的机关盒」'
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Block Gate "Duplex Barrier of Sun and Moon"',
                    zh_cn = '杜门「日月韬光二重结界」',
                }
            }
        },
        ['shouji-injury'] = {
            __default__ = {
                name = {
                    en_us = 'Injury Gate "Intergalactic War"',
                    zh_cn = '伤门「星系际大战」'
                }
            }
        },
        ['shouji-open'] = {
            EASY = {
                name = {
                    en_us = 'Open Gate "Circular Heaven Light"',
                    zh_cn = '开门「循环的天光」'
                }
            },
            NORMAL = '@ref:EASY',
            __default__ = {
                name = {
                    en_us = 'Open Gate "Chained Eightfold Heaven Light"',
                    zh_cn = '开门「连环八重天光」'
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
        tooshi = {
            name = {
                en_us = 'Tooshi Katsuyama',
                zh_cn = '堪山远志',
            },
            nickname = {
                en_us = 'Misleading Brown Fox',
                zh_cn = '误导人的棕色狐狸',
            }
        },
        cora = {
            name = {
                en_us = 'Cora Kurekagami',
                zh_cn = '吴镜珂络',
            },
            nickname = {
                en_us = 'Colorful Doppelganger',
                zh_cn = '多彩的分身',
            }
        },
        shouji = {
            name = {
                en_us = 'Shouji Yaeme',
                zh_cn = '八重目障子'
            },
            nickname = {
                en_us = ''
            }
        }
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
            reduceVisualQuality = {
                en_us = 'Reduce Visuals',
                zh_cn = '降低视觉质量',
            },
            [false] = {
                en_us = 'No',
                zh_cn = '否',
            },
            [true] = {
                en_us = 'Yes',
                zh_cn = '是',
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
                        en_us = 'Twisted Twigs',
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
                },
                stage3 = {
                    main = {
                        en_us = 'Dispersed Sunlight',
                        zh_cn = '晞日月之光烈',
                    },
                    small = {
                        en_us = 'STAGE 3   Pavilion of Visual Splendor',
                        zh_cn = 'STAGE 3   观艳馆',
                    }
                },
                stage4 = {
                    main = {
                        en_us = 'Finite and Borderless',
                        zh_cn = '有限无界的陷阱',
                    },
                    small = {
                        en_us = 'STAGE 4   Another Exhibition?',
                        zh_cn = 'STAGE 4   另一场展览？',
                    }
                },
                stage5 = {
                    main = {
                        en_us = 'Soaring High, a Narrow Sky',
                        zh_cn = '青云直上，以管窥天',
                    },
                    small = {
                        en_us = 'STAGE 5   Rise to the Sky',
                        zh_cn = 'STAGE 5   紧急升空',
                    }
                },
                stage6 = {
                    main = {
                        en_us = 'Head in the Clouds',
                        zh_cn = '怀宁一之心，处阒寂之地',
                    },
                    small = {
                        en_us = 'STAGE 6   Core of the Clouds',
                        zh_cn = 'STAGE 6   闲云内部',
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
            pieces = {
                en_us = '{piece}/{max} ^',
                zh_cn = '{piece}/{max} ^'
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
        PRACTICE = {
            headers = {
                segment = {
                    en_us = 'Segment',
                    zh_cn = '小节',
                },
                mode = {
                    en_us = 'Mode',
                    zh_cn = '模式',
                },
            },
            modes = {
                segment = {
                    en_us = 'Exit after segment',
                    zh_cn = '小节结束后退出',
                },
                stage = {
                    en_us = 'Exit after stage',
                    zh_cn = '关卡结束后退出',
                },
            },
            segments = {
                notReached = {
                    name = {
                        en_us = '???',
                        zh_cn = '???',
                    }
                },
                __default__ = {
                    name = "@nolocalize:1",
                },
                ['1-mid-kotoba'] = {
                    name = {
                        en_us = '1-MidBoss-Kotoba',
                        zh_cn = '1-道中Boss-言波',
                    }
                },
                ['1-mid-reimu'] = {
                    name = {
                        en_us = '1-MidBoss-Reimu',
                        zh_cn = '1-道中Boss-灵梦',
                    }
                },
                ['1-boss-kotoba'] = {
                    name = {
                        en_us = '1-Boss-Kotoba',
                        zh_cn = '1-Boss-言波',
                    }
                },
                ['1-boss-marisa'] = {
                    name = {
                        en_us = '1-Boss-Marisa',
                        zh_cn = '1-Boss-魔理沙',
                    }
                },
                ['2-branch'] = {
                    name = {
                        en_us = '2-Branch',
                        zh_cn = '2-分支',
                    }
                },
                ['2-boss'] = {
                    name = {
                        en_us = '2-Boss',
                        zh_cn = '2-Boss',
                    }
                },
                ['3-mid'] = {
                    name = {
                        en_us = '3-MidBoss',
                        zh_cn = '3-道中Boss',
                    }
                },
                ['3-boss'] = {
                    name = {
                        en_us = '3-Boss',
                        zh_cn = '3-Boss',
                    }
                },
                ['4-mid'] = {
                    name = {
                        en_us = '4-MidBoss',
                        zh_cn = '4-道中Boss',
                    }
                },
                ['4-boss'] = {
                    name = {
                        en_us = '4-Boss',
                        zh_cn = '4-Boss',
                    }
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
            continue = {
                en_us = 'Continue ({continues} left)',
                zh_cn = '续关 (剩余{continues}次)'
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
        level2 = {
            name = {
                en_us = 'Accelerating Voyage',
                zh_cn = '加速之旅',
            },
            description = {
                en_us = 'Stage 2\'s theme.\nAn enjoyable trip that urges you to go faster and faster.\nThough, the background of the stage is inspired by basalt columns and is quite barren.',
                zh_cn = '第二面的主题曲。\n令人愉快的旅程，催促你越来越快地前进。\n虽然游戏背景以玄武岩柱为灵感，显得相当荒凉。',
            }
        },
        level2b = {
            name = {
                en_us = 'Foxtrot Towards the Beyond',
                zh_cn = '通往远方的狐步舞',
            },
            description = {
                en_us = 'Tooshi Katsuyama\'s theme.\nA playful and bouncy composition. The whole song keeps using similar rhythm patterns, but the switching of instruments and melodies makes it feel fresh and interesting the whole time. The fox gave herself a stoic name to mislead people (^^;',
                zh_cn = '堪山远志的主题曲。\n一个有趣且弹跳的曲子。整首歌持续使用相似的节奏模式，但乐器和旋律的切换使曲子新鲜又有趣。狐狸给自己起了一个坚忍的名字来误导人们(^^;',
            },
        },
        level3 = {
            name = {
                en_us = 'Interactive Modern Art Museum',
                zh_cn = '互动式现代艺术馆',
            },
            description = {
                en_us = 'Stage 3\'s theme.\nFrom solemn corridor to lively exhibitions, the sudden bass does the transition well. The theme had changed a lot during the development. For example, the current transition part was intro and used to give a sense of broken TV.',
                zh_cn = '第三面的主题曲。\n从庄严的走廊到生动的展览，突如其来的低音很好地完成了过渡。开发过程中这首曲子发生了很大变化。例如，现在的过渡部分曾经是前奏，并且有种坏掉的电视的感觉。',
            }
        },
        level3b = {
            name = {
                en_us = 'Art of Kaleidoscope ~ Stacked Reflections',
                zh_cn = '万花筒艺术　～ Stacked Reflections',
            },
            description = {
                en_us = 'Cora Kurekagami\'s theme.\nI always think that "kaleidoscope" is somewhat cliche, but she literally creates kaleidoscopes and fun danmaku so there\'s no other choice.',
                zh_cn = '吴镜珂络的主题曲。\n我一直觉得“万花筒”这个词是陈词滥调，但她的机制确实是万花筒，并且弹幕也挺有趣，所以就这么叫吧。',
            }
        },
        level4 = {
            name = {
                en_us = 'Lost in Solaris',
                zh_cn = '索拉里斯的迷途',
            },
            description = {
                en_us = 'Stage 4\'s theme.\nDrenched in dreamy state, with a dangerous sounding transition. The craziness of the geometry has reached a new level, as well as the numerator of the time signature.',
                zh_cn = '第四面的主题曲。\n沉浸在梦幻的状态中，伴随着危险感的过渡。几何的疯狂达到了一个新的高度，就和拍号的分子一样。',
            }
        },
        level4b = {
            name = {
                en_us = 'Doors to Nowhere ~ Stitched Reality',
                zh_cn = '连通无处之门　～ Stitched Reality',
            },
            description = {
                en_us = 'Shouji Yaeme\'s theme.\nI tried to add some traditional Japanese song elements while it turned out to be weird, messy, and with the urgency of a tough battle. This theme also has a long history. Why koto feels very difficult to use?',
                zh_cn = '八重目障子的主题曲。\n我试着加入一些传统日本音乐元素，结果奇怪、混乱又有着激烈战斗的紧迫感。这首曲子也有很长一段历史。为什么筝感觉很难用呢？',
            }
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
    --@type table<string, NicknameLocalization>
    nickname = {},
    dialogues = {
        REIMUS1BossBefore = {
            hiKotoba = {
                en_us = 'Hey, Kotoba.',
                zh_cn = '嗨，言波！',
            },
            howsYourWorkHere = {
                en_us = 'Actually, you seem oddly carefree here—how exactly is your work here?',
                zh_cn = '你怎么看上去无忧无虑的，工作情况怎么样呀？',
            },
            workIsFine = {
                en_us = 'Er, everything is under control here..',
                zh_cn = '呃，一切尽在掌握之中……',
            },
            haveYouHeardThatMysteriousPlace = {
                en_us = 'Well, I didn\'t come here for small talk. Anyways, do you know anything about that weird, hidden place accessed from this travel hub?',
                zh_cn = '我不是来聊闲天的。有个奇怪隐秘的地方，能从这个旅行枢纽进入，这你知道吗？',
            },
            ughNo = {
                en_us = '...Uhh, no. (Crap, she knows I\'ll leave work early to check that place!?)',
                zh_cn = '呃，没有。(不好，她知道我会早退去那里？)',
            },
            howCanYouNotKnow = {
                en_us = 'How can you not know about it?? You\'re the manager of this entire travel hub, it\'d be an issue if you don\'t know about it! And frankly you\'re wasting my time.',
                zh_cn = '你怎么能不知道？？如果你身为管理员都不知道的话，那可就是严肃的问题了。我看你在浪费我的时间吧。',
            },
            ahhhIMeanIKnowBut = {
                en_us = 'Ahhh, fine! I mean, I\'ve heard rumors about it but I don\'t quite remember...',
                zh_cn = '啊啊！我是说，我听说过相关的流言，但不太记得了……',
            },
            aDanmakuBattleWouldHelpYouRemember = {
                en_us = '...Hmph, a danmaku battle would surely help clear up your head and fix that memory of yours, wouldn\'t it?',
                zh_cn = '……哼哼，打一场弹幕战会帮助你回忆起来的，对吧？',
            }
        },
        REIMUS1BossAfter = {
            yeahIRememberNow = {
                en_us = 'Alright, alright! It\'s all coming back to me now! Just stop shooting! It\'s probably over there!',
                zh_cn = '好啦，我全都记起来了！别打了！应该就是那边！',
            },
            soItsThisWay = {
                en_us = 'Ah, alright. So it\'s this way from here, thanks.',
                zh_cn = '那好。所以是这条路，谢了。',
            }
        },
        MARISAS1BossBefore = {
            wowThisPlaceSoCool = {
                en_us = 'Whoa, the deeper I go, the more this place splitting apart into smaller areas! This place is sick!',
                zh_cn = '哇，越往深处走，这个地方就越分裂成小块！太神奇了！',
            },
            welcomeToHyperbolicDomain = {
                en_us = 'Welcome to the Hyperbolic Domain, the travel hub of Gensokyo!',
                zh_cn = '欢迎来到双曲域，幻想乡的交通枢纽！',
            },
            ohHi = {
                en_us = 'Oh, neat, a resident! Hey there!',
                zh_cn = '哦，不错，有个人在！你好啊！',
            },
            wheresThatPlace = {
                en_us = 'Y\'know where\'s that rare, rumored place someone can access from this hub? \'Cause I\'m keeping my eyes squinting looking for it…',
                zh_cn = '你知道的，这交通枢纽通向那个罕见的地方，它在哪里？我一直在眯着眼睛找呢……',
            },
            waitThatThievishLook = {
                en_us = 'Wait, hold it right there… I think I know that shifty, thievish look from somewhere... What exactly are you planning?',
                zh_cn = '等等，我认识这贼眉鼠眼的表情……你在打什么主意？',
            },
            iMustStopYouNow = {
                en_us = 'Because if you\'re plotting to steal anything from this hub, I\'m not letting you!',
                zh_cn = '如果你想从这里偷东西，我才不会允许！',
            }
        },
        MARISAS1BossAfter = {
            youreStrong = {
                en_us = 'Ouch... you\'re pretty strong...',
                zh_cn = '啊呜，好强……',
            },
            ofCourseIAm = {
                en_us = 'Heh! That\'s just the power of daily hard work and curiosity I tell ya!',
                zh_cn = '哈哈！这是每日辛勤劳作和好奇心的力量，我跟你讲！',
            },
            whatAreYouLookingForHere = {
                en_us = '...So, what exactly are you looking for here?',
                zh_cn = '……所以你在这里找什么？',
            },
            thatPlace = {
                en_us = 'That hidden place accessible from this travel hub, obviously! I heard the space over there bends and warps crazily, it\'s like a magician\'s dream y\'know!',
                zh_cn = '显然是那个可以从双曲域进入的地方。我听说那里的空间疯狂地弯曲折叠，就和魔法使梦到的一样！',
            },
            thisWay = {
                en_us = 'Well, it\'s down this way. See the sign on the wall?',
                zh_cn = '就在这条路上。看到墙上的标志了吗？',
            },
            shouldTellMeInTheBeginning = {
                en_us = 'You could\'ve just told me from the beginning y\'know. But thanks for the heads up anyways!',
                zh_cn = '你应该一开始就告诉我的，知道吧。总之，多谢提醒！',
            }
        },
        KOTOBAS1BossBefore = {
            wheresThatPlace = {
                en_us = '...Where\'s that rare, rumored place someone can access from this hub? Hm…',
                zh_cn = '流言所说的罕见地方在哪里？嗯……',
            },
            waitThatThievishLook = {
                en_us = 'Wait, hold it right there… I think I know that shifty, thievish look from somewhere... What on earth is she planning?',
                zh_cn = '等等，我认识这贼眉鼠眼的表情……她在打什么主意？',
            },
            whoYouAre = {
                en_us = 'Stop right there! Who are you, and what do you think are you doing?',
                zh_cn = '别动！你是谁，你在做什么？',
            },
            imReimu = {
                en_us = 'How rude! I\'m Reimu Hakurei obviously, y\'know, the red-white shrine maiden.',
                zh_cn = '这么没礼貌！我显然是博丽灵梦。你知道的，神社的红白巫女。',
            },
            iJustMetHerYouKnow = {
                en_us = 'Nice try, but I just met her—the real Reimu—a minute ago! And she dresses in red and definitely doesn\'t wear black, y\'know?',
                zh_cn = '少来这套，我一分钟前刚见过她！她穿红色的，不是黑色，知道吧？',
            },
            herDressCanChangeColorYouKnow = {
                en_us = 'Pfft, her dress can change color whenever she wants, you know! Made of high-tech infrared threads!',
                zh_cn = '噗，她的裙子可以随意变色的，知道吧？高科技红外线编出来的！',
            },
            thatsLame = {
                en_us = 'Infrared "fabric?!" No, that\'s entirely "fabricated!" Stop bluffing!',
                zh_cn = '红外线编的？不会编就别编了！',
            },
            okthenImMarisa = {
                en_us = 'Tch, fine, you caught me, I\'m Marisa Kirisame!',
                zh_cn = '嘁，好吧，我是雾雨魔理沙！',
            },
            andIllPunishYou = {
                en_us = 'And you\'ll pay to be punished for ruining my disguise right now for sure!',
                zh_cn = '竟敢揭穿我的伪装，接受惩罚吧！',
            }
        },
        KOTOBAS1BossAfter = {
            impossible = {
                en_us = 'No way… I lost after my fake Reimu setup?! Man, you really don\'t hold back at all dude… Man, whatever, I\'m leaving anyways.',
                zh_cn = '不可能……自称灵梦怎么会输呢？！你怎么都不放水？不管了，我溜了。',
            },
            whatStrangePerson = {
                en_us = 'What a strange girl… She didn\'t even care her lasers were curved…',
                zh_cn = '真是个奇怪的人……她都不在意自己的激光变弯了……',
            }
        },
        S2Branch1 = {
            hiThere = {
                en_us = 'Hi there, traveler!',
                zh_cn = '嗨，旅行者你好呀。',
            },
            areYouGoingForward = {
                en_us = 'Planning on heading deeper inside? I can guide you~.',
                zh_cn = '要往前深入吗？我可以带路哦～',
            },
            thereAreTwoPaths = {
                en_us = 'Watch out though, there are two paths ahead... the left one is safer, but the right one has far more rewards.',
                zh_cn = '注意了，前面有两条路……左边的路更安全，右边的路奖励更多。',
            },
            stayAtLeftOrRightSide = {
                en_us = 'Go and quickly make your choice! Drift over to left or right side of the clearing.',
                zh_cn = '做出你的选择吧！待在屏幕左侧或右侧。',
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
                en_us = 'One...!',
                zh_cn = '一……！',
            }
        },
        S2BranchLeft = {
            youChoseLeft = {
                en_us = 'Hm, playing it safe aren\'t we? Alright, follow me!',
                zh_cn = '嗯，安全优先吗？好的，跟我来！',
            },
        },
        S2BranchRight = {
            youChoseRight = {
                en_us = 'Ah, chasing after the rewards? Hm, I like your spirit! Follow me!',
                zh_cn = '啊哈，追逐奖励吗？好的，跟我来！',
            },
        },
        REIMUS2BossBefore = {
            stop = {
                en_us = 'Stand still, I\'m sick of chasing you around! ',
                zh_cn = '停下，我受不了继续追着你跑了！',
            },
            ohYouAreStillFollowing = {
                en_us = 'Oh, still at my tail?',
                zh_cn = '哦，你还跟着呢？',
            },
            youAreReallyGood = {
                en_us = 'You\'re quite resilient at walking these trails~',
                zh_cn = '你真的很擅长徒步啊～',
            },
            huhWhat = {
                en_us = 'Huhh? Of course not, I can literally fly anyways.',
                zh_cn = '啊？当然不是，我可是会飞的哦。',
            },
            youAreMaliciousYoukai = {
                en_us = 'Either way, you\'re just another malicious youkai causing trouble, aren\'t you?',
                zh_cn = '不管怎样，你又是个惹是生非的妖怪吧？',
            },
            whyYouSayThat = {
                en_us = 'Meee? Troublesome? Why do you say that? I\'m just nicely leading the way for you~.',
                zh_cn = '我——？惹事？为什么这么说？我可是很好心地为你带路哦～',
            },
            yourLantern = {
                en_us = 'That annoying lantern of yours is not normal. It\'s totally messing with my eyes.',
                zh_cn = '你那烦人的灯笼不正常，它看得我眼都花了。',
            },
            itCanAffectOthersMinds = {
                en_us = 'From it\'s aura, you\'re just messing with my head here, and things from afar and up-close seems way too much for my eyes. I don\'t have time for your mind games!',
                zh_cn = '它的气场让我头昏脑胀，这忽近忽远的地形也让我受不了。我没时间和你玩这种把戏！',
            },
            ohIDontKnowWhyYouGuessThat = {
                en_us = 'Oh my, I don\'t know why\'d you guess that~.',
                zh_cn = '哦我的天，我不知道你为什么会这么猜～',
            },
            butDie = {
                en_us = 'But rules are rules~, prepare to crash down to the bottom of the warped world!',
                zh_cn = '但是规矩就是规矩～准备好跌入这世界的最底端吧！',
            }
        },
        REIMUS2BossAfter = {
            wahISurrender = {
                en_us = 'Waaah! Okay, okay, I surrender!',
                zh_cn = '哇！好吧，好吧，我投降！',
            },
            whatWereYouTryingToDo = {
                en_us = 'Start talking. What exactly were you trying to do?',
                zh_cn = '老实交代，你到底想干什么？',
            },
            iJustLikePranking = {
                en_us = 'I just wanted to pull off a harmless little prank! ',
                zh_cn = '我只是想搞个无害的小恶作剧而已。',
            },
            leadPeopleDeepAndAbandonThem = {
                en_us = '...You know, leading people deep into this deep perspective warp and completely ditching them.',
                zh_cn = '……也就是，把人带到这种地方深处然后抛下他们。',
            },
            soIsThatPlaceReallyHere = {
                en_us = 'How incredibly annoying... So is that "obscure beautiful place" really past here?',
                zh_cn = '真是烦人啊……所以那个“美丽的地方”真的在前面吗？',
            },
            yeahYouSeeItFromHere = {
                en_us = 'Alright, fine! It\'s called Pavilion of Visual Splendor. Look—you can even see it from here.',
                zh_cn = '是呀！它叫“观艳馆”，你看，从这里能直接看到它了。',
            },
            huhSoTheTrick = {
                en_us = 'Oh? Hmph, so to make the prank more convincing, you actually had to lead me the correct way...',
                zh_cn = '哦？哼，为了让恶作剧更可信，其实带的是正确的路吗……',
            },
            okBye = {
                en_us = 'Whatever, I\'m going there.',
                zh_cn = '好吧，我去那边了。',
            }
        },
        MARISAS2BossBefore = {
            whyGoingSoFast = {
                en_us = 'Hey hey wait up! Why are you going so fast when the geometry here\'s all messed up!? Wait for me!',
                zh_cn = '嗨，等一下！这里的空间都这么乱了，你为什么还跑那么快？等等我！',
            },
            ohYouAreStillFollowing = {
                en_us = 'Oh, still at my tail?',
                zh_cn = '哦，你还跟着呢？',
            },
            youAreReallyGood = {
                en_us = 'You\'re quite resilient at walking these trails~',
                zh_cn = '你真的很擅长徒步啊～',
            },
            huhWhat = {
                en_us = 'Eh? You\'re probably right about that.. (Actually, I was just cruising along with with my broom.)',
                zh_cn = '啊？那，那当然了……（其实，我是骑着扫帚行驶）',
            },
            youDidWantToAbandonMe = {
                en_us = 'But hold on for a sec, you seemed like you were gonna abandon me here. Especially with that weird lantern bending my line of perception here for real.',
                zh_cn = '但是等一下，你这是想抛下我吧。尤其是那个奇怪的灯笼，扭曲我的视线。',
            },
            calmDownPlease = {
                en_us = '"Bending the line of perception?" Nonsense, why not just calm down for a moment, please?',
                zh_cn = '“扭曲视线？”胡说，为什么不先冷静一下呢？',
            },
            lookAtMyLantern = {
                en_us = 'Now, why don\'t you just look at my lantern? Why would I bring it with me, if not for leading people in this mind-bending area?',
                zh_cn = '现在，你再仔细看看我的灯笼！如果不是为了在这扭曲的地方带路，我为什么要带着它？',
            },
            whyWouldIKnowThat = {
                en_us = 'Eh? Why would I look at that? Maybe it\'s magical as my broom? It\'s got that certain value to it enough to mess with the heads of people.',
                zh_cn = '呃，为什么我要看？也许它像我的扫帚一样有魔力？它是足以让人头晕目眩。',
            },
            die = {
                en_us = '...What? How did you know that? Whatever, if you\'ll bypass my rules, then prepare to crash down to the bottom of my warped world!',
                zh_cn = '……什么？你怎么知道的？哼哼，竟敢坏了规矩，准备好跌入这世界的最底端吧！',
            }
        },
        MARISAS2BossAfter = {
            wahISurrender = {
                en_us = 'Waaah! Okay, okay, I surrender!',
                zh_cn = '哇！好吧，好吧，我投降！',
            },
            badFox = {
                en_us = 'Hmph, you\'re pretty annoying for a kitsune. Whatever you were doing with that lantern was definitely no good.',
                zh_cn = '烦人的狐狸，你这灯笼果然不干好事。',
            },
            iSeeTheresABuilding = {
                en_us = 'I see there\'s a building in the distance. Y\'know its name?',
                zh_cn = '我看到远处有一栋建筑。你知道它的名字吗？',
            },
            itsName = {
                en_us = '...Its name is Pavilion of Visual Splendor.',
                zh_cn = '……它的名字叫“观艳馆”。',
            },
            strangeName = {
                en_us = 'Pretty strange name! But it sounds like my target. Thanks!',
                zh_cn = '好奇怪的名字！但听起来就是我的目的地。谢啦！',
            }
        },
        KOTOBAS2BossBefore = {
            areWeAlmostThere = {
                en_us = 'Eh... Are we almost there?',
                zh_cn = '呃……我们快到了吗？',
            },
            ohYouAreStillFollowing = {
                en_us = 'Oh, still at my tail?',
                zh_cn = '哦，你还跟着呢？',
            },
            youAreReallyGood = {
                en_us = 'You\'re quite resilient at walking these trails~',
                zh_cn = '你真的很擅长徒步啊～',
            },
            whyAmIFast = {
                en_us = 'Heh, I guess so! I\'ve been getting weirdly faster than earlier though...',
                zh_cn = '只要心情愉快，速度就能变快了！',
            },
            lookAtMyLantern = {
                en_us = 'Now, how about you take a look at my lantern~?',
                zh_cn = '好。现在看看我的灯笼，怎么样～？',
            },
            yeah = {
                en_us = 'Err... Yeah...',
                zh_cn = '嗯……好的……',
            },
            iFeelStrange = {
                en_us = '...Heh... I feeel.. a little "strange and funny" around it...',
                zh_cn = '……哈哈……我感觉……有点奇怪又好玩？',
            },
            enjoyTheDance = {
                en_us = 'Under my lantern... Now, dance with me!',
                zh_cn = '在灯笼光芒下……现在，和我一起跳舞吧！',
            }
        },
        KOTOBAS2BossAfter = {
            wahISurrender = {
                en_us = 'Waaah! I surrender!! You\'re more resilient than I thought!',
                zh_cn = '哇！我投降！你比我预期的要坚强！',
            },
            whatWasIDoing = {
                en_us = '...Huh. What on Oxford\'s Dictionary was I doing?',
                zh_cn = '……什么奇怪押韵。我在做什么来着？',
            },
            soDoYouReallyKnowThatPlace = {
                en_us = '...Oh right! So do you really know that place? Y\'know, that pavilion?',
                zh_cn = '……哦对！所以你真的知道那个地方吗？那个什么馆？',
            },
            itsCloseYouCanSeeItFromHere = {
                en_us = 'Ehh? You mean the "Pavilion of Visual Splendor"? It\'s close, look you can even see it from here!',
                zh_cn = '你是说“观艳馆”？很近了，你从这里就能看到它！',
            },
            ohSoThisIsntAScam = {
                en_us = 'Oh, so this isn\'t a scam like any other lousy youkai would usually do? I\'m still confused...',
                zh_cn = '哦，所以这不是那种讨厌妖怪的骗局？我还是没明白……',
            },
            ofCourse = {
                en_us = '...Of course not! As long as you keep up your speed, you can reach your destination.',
                zh_cn = '……当然不是。只要速度跟得上，就的确能到达目的地。',
            },
            overThere = {
                en_us = 'See? The pavilion\'s just up ahead you see? (This girl is bothersome already!)',
                zh_cn = '看到了吗？观艳馆就在那边了！（你赶紧走开吧！）',
            },
            whateverImHeadingThere = {
                en_us = 'Oh. Whatever. I\'m heading there; peace out, girl-fox!',
                zh_cn = '哦，随便啦，我是要去那里。再见，狐狸！',
            }
        },
        REIMUS3BossBefore={
            thePavilionIsSoBeautiful = {
                en_us = 'Gosh, this pavilion is actually pretty stunning.',
                zh_cn = '哇哦，观艳馆真是震撼。',
            },
            whoWouldBeTheOwner = {
                en_us = 'Now, if I\'m probably right by intuition.. could that weird mirror girl from earlier own this place?',
                zh_cn = '如果我的直觉没错，之前那个奇怪的镜女人是这里的主人吧？',
            },
            aVisitor = {
                en_us = 'Ah, a shrine maiden visiting! Yes, that "mirror girl" is me.',
                zh_cn = '啊，巫女来拜访了！是的，那个“镜女人”是我。',
            },
            thisCorridorIsMyPlace = {
                en_us = 'This corridor is my place. Say, Miss Shrine Maiden, is the view of my corridor not magnificent?',
                zh_cn = '这条走廊是我的地盘。你说，巫女小姐，我的走廊是不是很壮丽？',
            },
            iNeverSeenSuchModernPlaceInGensokyo = {
                en_us = 'Hmm... I haven\'t seen such a place like this in Gensokyo other than the Eientei estate\'s hallway corridors.',
                zh_cn = '嗯……和永远亭的走廊比起来，这地方过于摩登了……全幻想乡都没见过。',
            },
            youKnowInteractiveArt = {
                en_us = 'Ah, but this is more than just a hallway! Do you know interactive art Miss Shrine Maiden?',
                zh_cn = '除了走廊，还有更多好东西呢！你知道互动艺术吗，巫女小姐？',
            },
            what = {
                en_us = 'No idea whatever that is. Is it some outside-dialect way of saying "danmaku"? Or are you asking to be beat up?',
                zh_cn = '那是什么东西，是“弹幕”的非主流方言吗？还是你想被揍一顿？',
            },
            letsHaveFun = {
                en_us = 'Perhaps I can show you, Miss Shrine Maiden. Let us play within the reflection!',
                zh_cn = '我来展示给你看，巫女小姐。我们在镜像中游玩吧！',
            }
        },
        REIMUS3BossAfter = {
            notGoodForMyEyes = {
                en_us = 'Ack, your so-called "interactive art" is straining my eyes! Stop that!',
                zh_cn = '啊，你所谓的“互动艺术”怕是对我的眼睛不好！停下！',
            },
            theNextExhibition = {
                en_us = 'Ah, alas... if my art was not beautiful for you, there is another "exhibition" up next, becareful with the looping spaces up ahead Miss shrine maiden.',
                zh_cn = '啊，唉唉……如果我的艺术不够美，那里还有下一场展览等着你。小心那里循环的空间，巫女小姐。',
            },
            bye = {
                en_us = 'So it was that easy for you to say? Agh, whatever, my eyes are still straining a little. I\'m leaving to find the cause of this, bye.',
                zh_cn = '你早说下一场展览在哪啊，我的眼睛还酸痛着呢。我先走了，拜拜。',
            }
        },
        MARISAS3BossBefore = {
            soManyMirrors = {
                en_us = 'Woah, there\'s tons of reflections and portraits around here!',
                zh_cn = '哇，这么多画和镜子！',
            },
            infinityMirrorAtCertainAngle = {
                en_us = 'If I point my non-directional lasers at certain angles, I could see infinite lasers through these mirrors for sure!',
                zh_cn = '如果我发射非定向激光，在某个角度就能看到无穷多的激光吧！',
            },
            enjoying = {
                en_us = 'Enjoying the exhibition?',
                zh_cn = '在欣赏展览吗？',
            },
            thisCorridorIsMyPlace = {
                en_us = 'This corridor is my place, Miss Magician. Do you like the kaleidoscopic art of the fairies here?',
                zh_cn = '这条走廊是我的地盘，魔法使小姐。你喜欢这里妖精组成的万花筒艺术吗？',
            },
            whyYouHaveYourBackToMe = {
                en_us = 'Eh? Why do you have your back at me? That\'s not everyday I see a boss-type do that, \'cause usually only a certain miko or dollmaker would be facing away when being mad at me.',
                zh_cn = '嗯？你为什么背对着我啊？我平时见到的boss可不这样。只有某个巫女和人偶师，在对我发火时才会背对着我。',
            },
            imNot = {
                en_us = 'I reassure you, I am not.',
                zh_cn = '并非如此，我没发火。',
            },
            myReflectionIsFacingYou = {
                en_us = 'Is my reflection not facing you, Miss Magician?',
                zh_cn = '我在镜中的像难道不是面向你的吗，魔法使小姐？',
            },
            ughhYeah = {
                en_us = 'Uhh, yeah, sorta. Still a wack to me. You sure you ain\'t mad at me for barging in here?',
                zh_cn = '呃，行吧，还是挺奇怪的。我闯进来你真的不生气？',
            },
            youKnowInteractiveArt = {
                en_us = 'There is a far more perplexing idea you mayhaps approve of. Do you happen to know interactive art?',
                zh_cn = '你或许会喜欢这个更复杂的想法。你知道互动艺术吗？',
            },
            likeBodyPaintingThing = {
                en_us = 'Like "smearing pigments onto your body" sorta thing like your reflection? Yeah, probably.',
                zh_cn = '像是在身上涂抹颜料这种东西，就和你镜子里一样？',
            },
            notQuiteThat = {
                en_us = 'Not quite that, but perhaps it\'s similar to your description.',
                zh_cn = '不完全是那样，但有点类似。',
            },
            butYoullSeeNow = {
                en_us = 'But here, you will see now, Miss Magician!',
                zh_cn = '不过你现在就会看到的，魔法使小姐！',
            }
        },
        MARISAS3BossAfter = {
            iHaveToLearnSuchMagic = {
                en_us = 'Man, I gotta learn what type of magic you\'re doing to do all these wacky and pretty stuff!',
                zh_cn = '我说，我必须学会你这种炫酷魔法！',
            },
            iCanPlayWithItAllDay = {
                en_us = 'I\'d be playing with it all day if I could do it way earlier y\'know!',
                zh_cn = '我要是学会了，我可以玩一整天啊！',
            },
            yeahYouCanTry = {
                en_us = 'Thank you for your approval of my reflective art, Miss Magician. They\'re entirely also free for you to try; just be careful up ahead with the next "exhibition."',
                zh_cn = '感谢你的认可，魔法使小姐。你当然可以试试，试试又不花钱。不过，你可要当心下一场“展览”啊。',
            },
            imHeadingToTheNextExhibition = {
                en_us = 'Alright, I\'m heading at that next exhibition, thanks mirror girl.',
                zh_cn = '好的，我去下一场展览了，谢谢镜女人。',
            }
        },
        KOTOBAS3BossBefore = {
            paintingsOnTheWall = {
                en_us = '...Paintings on the walls...',
                zh_cn = '墙上的画……',
            },
            theirContentIsOnlyVisibleFromMirrors = {
                en_us = 'Hm, it looks like the contents are only visible from these reflective mirrors.',
                zh_cn = '嗯，它们的内容只能从镜子里看到。',
            },
            yeahItsFunny = {
                en_us = 'You are not entirely wrong, miss. It is quite a droll, is it not?',
                zh_cn = '你说的不错，小姐。这很滑稽，对不对？',
            },
            thisCorridorIsMyPlace = {
                en_us = 'Because, this corridor is my place.',
                zh_cn = '因为，这条走廊是我的地盘。',
            },
            ohThatsTrueReflectionOfYourSkills = {
                en_us = 'Ohhh, so that\'s true "reflection" of your skills! Must be fun seeing doubles on the hubble.',
                zh_cn = '哦，那的确“反映”了你的技艺！',
            },
            haha = {
                en_us = 'Hehe, I see what you mean there, miss.',
                zh_cn = '哈哈，我明白你的意思了，小姐。',
            },
            youKnowInteractiveArt = {
                en_us = 'But there\'s more to this corridor! Do you happen to know interactive art?',
                zh_cn = '不过这里还有更多好东西呢！你知道互动艺术吗？',
            },
            iGuessThatWouldBeCool = {
                en_us = 'Probably! Maybe. But, I guess that would be cool!',
                zh_cn = '应该吧！呃，可能吧。不过，我猜那会很酷！',
            },
            ofCourse = {
                en_us = 'Of course! Let us have joy within the reflections!',
                zh_cn = '当然啦！和我一起享受镜面倒影吧。',
            }
        },
        KOTOBAS3BossAfter = {
            ughhIFeelDizzy = {
                en_us = 'Ughh, man, I feel dizzy...',
                zh_cn = '呃，我说，我有点头晕……',
            },
            butItsTrulyInteresting = {
                en_us = 'But wait, your "art" is throwing dart and duplicating it into a rampart... You\'re pretty interesting, y\'know?',
                zh_cn = '不过，你的“艺术”把“一”支箭复制成无“数”支箭……这确实很有趣。',
            },
			thanksForLikingArt = {
				en_us = 'Perhaps you can say that, miss. Thank you for approval. You may be more interested in the other "exhibition" up ahead.',
				zh_cn = '感谢您喜欢我的作品，小姐。前面还有一个“展览”，您可能会更喜欢。',
			},
            imConsideringAddingMirrorsToHyperbolicDomain = {
                en_us = 'Hmmm, I might be considering to add mirrors to the Hyperbolic Domain! But true, I want to see the next exhibition, see ya mirror girl!',
                zh_cn = '我要考虑在双曲域里加上镜子！不过的确，我想去看下一个展览。拜拜，镜女人！',
            },
        },
        REIMUS4BossBefore = {
            theSpaceIsMoreAndMoreAbnormal = {
                en_us = 'Hold on, the space here is more abnormal. When was the last time I move "freely" like this?',
                zh_cn = '怎么回事，空间越来越奇怪了。上次这样“自由”地移动是什么时候？',
            },
            isThisAPotentialIncident = {
                en_us = 'Ugh, could this be another potential incident during this time of solving THIS incident?',
                zh_cn = '唉，难道是潜在的异变？',
            },
            aNewRoomInCageShape = {
                en_us = 'Another new room in the shape of a cage... it seems this space "sometimes" loops around onto itself, no wonder.',
                zh_cn = '又一个新房间，还是笼子形状的……',
            },
            yeahItsForYou = {
                en_us = 'Exactly, built just for you to be trapped within.',
                zh_cn = '正确，是给你准备的。'
            },
            ninjaInGensokyo = {
                en_us = '!?  A ninja? In a warped space of all places??',
                zh_cn = '幻想乡里出现了忍者？！'
            },
            thisIsSurelyAnIncident = {
                en_us = 'Now I\'m more convinced there is something up than just some space-warping incident.',
                zh_cn = '这的确是异变啊！'
            },
            stopTalkingToYourself = {
                en_us = 'Stop talking to yourself, Hakurei shrine maiden.',
                zh_cn = '别自言自语了，博丽的巫女。'
            },
            youAreThePerfectTarget = {
                en_us = 'You are the target perfect for assassination since the majority of Gensokyo knows who you are... Now,',
                zh_cn = '你是完美的刺杀目标，因为幻想乡人人都认识你……现在，'
            },
            tryNotGetLostInPortals = {
                en_us = 'I\'d like to see you to trying to keep your gohei rod intact when trying to escape my portals! Kuukan-no-jutsu!',
                zh_cn = '可别在穿过传送门时把御币折断了！空间之术！'
            }
        },
        REIMUS4BossAfter = {
            iWin = {
                en_us = '...And I won anyways. Do you have a sort of grudge against me that you decided to be a stalker? Talk about weird.',
                zh_cn = '……我还是赢了。你是对我有什么不满吗，为什么要跟踪我？奇怪。',
            },
            yeahIllWalkYouOutside = {
                en_us = 'Ugh, of course I lost to the Shrine Maiden of Paradise... Fine, I\'ll escort you outside.',
                zh_cn = '唉，当然我会输给乐园的巫女……好吧，我送你出去吧。',
            },
            wait = {
                en_us = 'Wait wait, there\'s something off here...',
                zh_cn = '等等，有点不对劲……',
            },
            aboutThisSpatialAbility = {
                en_us = 'Something about this spatial warping... It feels too strong.',
                zh_cn = '这种空间能力，感觉太强大了。',
            },
            itCouldntBeFromYou = {
                en_us = 'It couldn\'t be yours, right? Seems the aura is different than yours.',
                zh_cn = '不可能是你的能力吧？这气场和你的不一样。',
            },
            leave = {
                en_us = '...What? Asking me such things after our battle? Because if you\'re planning to go through that hole from above, you\'re free to go up there anyways. Leave.',
                zh_cn = '……嗯？问我这种事情吗？如果你想从上面那个洞出去，那也随便。快走。',
            },
            isntTheHoleInTheCeilingStrange = {
                en_us = 'Wow, rude. Anyways—hold on, the hole up there is pretty strange.',
                zh_cn = '好没礼貌。这么一说，天花板上的洞是很奇怪。',
            },
            illGoThere = {
                en_us = '...I\'ll go there and check it out.',
                zh_cn = '……我去看看。',
            }
        },
        MARISAS4BossBefore = {
            iveSeenEnoughWhereIsExit = {
                en_us = 'Gah, I\'ve seen enough. Where is the exit here? The space here is practically looping!',
                zh_cn = '哎呀，我已经看够了。出口在哪里？这里的空间一直在循环！',
            },
            aStrangeRoomWhoIsIt = {
                en_us = 'Now another huge space. Is anyone other than those fairies here?',
                zh_cn = '更大些的房间。除了妖精还有别人在吗？',
            },
            mustBeAnotherVisitor = {
                en_us = 'Or is it just gonna be another random visitor?',
                zh_cn = '只是另一个游客啊。',
            },
            thatsABigMistake = {
                en_us = 'That would be a big mistake.',
                zh_cn = '那可是个大错误。',
            },
            noYouDontHaveMagicCircle = {
                en_us = 'Naah it ain\'t. I\'m not seeing any magic sigil anywhere from you, so you aren\'t a threat man.',
                zh_cn = '才不是。你身下没有魔法阵，所以你不是个威胁。',
            },
            haGuessWhyIDontCastIt = {
                en_us = 'Ha, try guessing why I don\'t cast one.',
                zh_cn = '哈哈！猜猜我为什么不施放魔法阵？',
            },
            cuzYouDontHaveMagicPowerNotLikeMe = {
                en_us = 'Because I bet\'cha don\'t have any sorta magic power! It\'s a privilege to meet a great magician like me, y\'know.',
                zh_cn = '因为我敢打赌，你没有一丁点魔力啊！你能遇到像我这样的大魔法使应该感到很荣幸呢。',
            },
            wrongItsForStealth = {
                en_us = 'Wrong, it\'s for stealth.',
                zh_cn = '错了！是为了潜行。',
            },
            arentYouAlreadyInFrontOfMe = {
                en_us = 'Aren\'t you already in front of me? You probably didn\'t even bother or are you a show-off?',
                zh_cn = '你不就在我面前吗？',
            },
            iWasWatchingYouWhenYouWereWanderingAround = {
                en_us = 'I was watching you when you were wandering around—just dodging in a looping space. A clueless magician you are.',
                zh_cn = '我在你四处游荡的时候就一直在观察你。',
            },
            andIvePreparedPersonalizedAttacks = {
                en_us = '...And while you were lost, I\'ve prepared personalized attacks for you. Kuukan-no-Jutsu!',
                zh_cn = '……在你迷路的时候，我已经准备好了针对你的攻击。空间之术！',
            },
        },
        MARISAS4BossAfter = {
            stillBetterThanTheWorstMushroomIHad = {
                en_us = 'Still better than the worst magic mushroom I had.',
                zh_cn = '还是比我吃过的最离谱的魔法蘑菇好。',
            },
            imGenuinelyCuriousAboutIt = {
                en_us = 'Ehh, I\'m now genuinely curious about that mushroom.',
                zh_cn = '呃，我现在真心好奇那蘑菇是怎么回事。',
            },
            whateverYouCanLeave = {
                en_us = '...Ahem. You can leave now.',
                zh_cn = '……总之，你可以走了。',
            },
            theClosestExitIs80RoomsAway = {
                en_us = 'The closest exit is 80 rooms away. I\'ll walk you there.',
                zh_cn = '最近的出口在80个房间之外。我送你过去吧。',
            },
            really = {
                en_us = 'Really? You\'re being oddly nice about it... What, trying to act like you didn\'t just lose?',
                zh_cn = '真的吗？现在怎么这么好心了……难道是在装作没输？',
            },
            aHoleInTheCeiling = {
                en_us = 'Buut there is a hole in the ceiling, weird.',
                zh_cn = '但天花板上有个洞，奇怪。',
            },
            takeThisFasterWay = {
                en_us = 'I\'d rather take this the faster way! Bye ninja-stalker!',
                zh_cn = '我还是走这条更快的路吧！再见了跟踪狂忍者！',
            },
            thatsNotTheExit = {
                en_us = 'Hold on, that\'s not the exit—',
                zh_cn = '停下，那不是出口——',
            },
        },
        KOTOBAS4BossBefore = {
            theRoomsDynamicallyChangeStructure = {
                en_us = 'The rooms dynamically change structure? Huh, cool.',
                zh_cn = '房间的结构在动态变化？有点意思。',
            },
            finallyADifferentRoom = {
                en_us = 'Oh, finally, a different room!',
                zh_cn = '终于，一个不同的房间！',
            },
            isntItTheTravelHubManager = {
                en_us = 'Ah, hold on a second. Aren\'t you the travel hub manager of the Hyperbolic Domain?',
                zh_cn = '啊，等等，那不是交通枢纽“双曲域”的管理员吗？',
            },
            yeahWhoAreYou = {
                en_us = 'Yeah, and who are you? Weren\'t you that silhouette attacking me earlier?',
                zh_cn = '是啊，你是哪位？你就是之前袭击我的人？',
            },
            shouji = {
                en_us = 'Yess yes, I\'m Shouji Yaeme, pleasure meeting you. The maze was set up by me.',
                zh_cn = '是，我是八重目障子，很高兴见到你。迷宫就是我设置的。',
            },
            thisPavillionGetsManyVisitors = {
                en_us = 'Because ever since the appearance of Hyperbolic Domain, this pavilion gets many visitors with your help, manager. Would a pay back not be appropriate?',
                zh_cn = '双曲域出现后，观艳馆有了很多访客呢。是时候报答了。',
            },
            toPayBackLetsBattle = {
                en_us = 'Because if so, I shall pay you back with a duel! Kuukan-no-Jutsu!',
                zh_cn = '作为报答，我来和你决斗吧！空间之术！',
            },
        },
        KOTOBAS4BossAfter = {
            imExhausted = {
                en_us = '...Maaan, I\'m exhausted...',
                zh_cn = '……我说，我累坏了……',
            },
            theBattleIsntEnding = {
                en_us = 'And the battle isn\'t ending? Aw shucks.',
                zh_cn = '战斗还没结束吗？差不多得了！',
            },
            iStillHaveNineStars = {
                en_us = 'Not now! I still have nine flying star spellcards—',
                zh_cn = '还没结束！我还有九张星符——',
            },
            ahhWhatToDo = {
                en_us = 'Agghh!!! What to do?!',
                zh_cn = '啊啊，我该怎么办？',
            },
            andEightGods = {
                en_us = '—and eight divine spellcards left!',
                zh_cn = '——以及八张神符！',
            },
            hmm = {
                en_us = 'Hmmmm, darn, I have to think!!',
                zh_cn = '嗯，该死，我得好好想想！',
            },
            theresAHoleInTheCeiling = {
                en_us = 'Oh! Wow! There\'s a hole in the ceiling!',
                zh_cn = '哦，天花板上有个洞！',
            },
            takeOffNow = {
                en_us = 'I\'ll be taking off now Miss Shouji! Bye now!',
                zh_cn = '我要远走高飞，障子小姐！再见啦！',
            }
        }
    },
}