#ifndef JOB_H
#define JOB_H

#include<string>
#include<map>

enum Job
{
    // 冒险家
    Hero, //英雄
    Paladin, //圣骑士
    DarkKnight, //黑骑士
    Bishop, //主教
    ArchMage_Fire_Poison, //大魔导师(火,毒)
    ArchMage_Ice_Lightning, //大魔导师(冰,雷)
    BowMaster, //箭神
    Marksman, //神射手
    PathFinder, //开拓者
    Shadower, //暗影神偷 (刀飞)
    NightLord, //夜使者 (标飞)
    BladeMaster, //影武者 (双刀)
    Buccaneer, //拳霸
    Corsair, //枪神
    CannonMaster,//重炮指挥官

    //六英雄
    Aran, //狂狼勇士
    Evan, //龙魔导士
    Mercedes, //精灵游侠
    Phantom, //幻影侠盗
    Luminous, //夜光
    Shade, // 隐月

    //西格诺斯骑士团
    Mihile, //米哈逸
    DawnWarrior, //圣魂剑士
    BlazeWizard, //烈焰巫师
    WindArcher, //破风使者
    NightWalker, //暗夜行者
    ThunderBreaker, //闪雷悍将

    //末日反抗军
    DemonSlayer, //恶魔杀手
    DemonAvenger, //恶魔复仇者
    Blaster, //爆拳枪神
    BattleMage, //炼狱巫师
    WildHunter, //狂豹猎人
    Mechanic, //机甲战神
    Xenon, //杰诺

    //超新星
    Kaiser, //凯撒
    Cadena, //卡蒂娜
    AngelicBuster, //天使破坏者
    Kain, //凯殷

    //雷普
    Adele, //阿黛尔
    Ark, //亚克
    Illium, //伊利恩

    //阿尼玛
    Hoyoung, //虎影
    Lara, //菈菈

    //其他
    Zero, //神之子
    Kinesis, //凯内西斯

    //海外职业
    Kanna, //阴阳师
    Hayato, //剑豪
    BeastTamer, //幻兽师
    Jett, //杰特
    MoXuan //墨玄
};
const std::map<std::string, Job> JobNameMap = {
    // 冒险家
    {"英雄",Hero},
    {"圣骑士", Paladin},
    {"黑骑士", DarkKnight},
    {"主教", Bishop},
    {"大魔导师(火,毒)", ArchMage_Fire_Poison},
    {"大魔导师(冰,雷)", ArchMage_Ice_Lightning},
    {"箭神", BowMaster},
    {"神射手", Marksman},
    {"开拓者", PathFinder},
    {"暗影神偷", Shadower},
    {"夜使者", NightLord},
    {"影武者", BladeMaster},
    {"拳霸", Buccaneer},
    {"枪神", Corsair},
    {"重炮指挥官", CannonMaster},

    //六英雄
    {"狂狼勇士", Aran},
    {"龙魔导士", Evan},
    {"精灵游侠", Mercedes},
    {"幻影侠盗", Phantom},
    {"夜光", Luminous},
    {"隐月", Shade},

    //西格诺斯骑士团
    {"米哈逸", Mihile},
    {"圣魂剑士", DawnWarrior},
    {"烈焰巫师", BlazeWizard},
    {"破风使者", WindArcher},
    {"暗夜行者", NightWalker},
    {"闪雷悍将", ThunderBreaker},

    //末日反抗军
    {"恶魔杀手", DemonSlayer},
    {"恶魔复仇者", DemonAvenger},
    {"爆拳枪神", Blaster},
    {"炼狱巫师", BattleMage},
    {"狂豹猎人", WildHunter},
    {"机甲战神", Mechanic},
    {"杰诺", Xenon},

    //超新星
    {"凯撒", Kaiser},
    {"卡蒂娜", Cadena},
    {"天使破坏者", AngelicBuster},
    {"凯殷", Kain},

    //雷普
    {"阿黛尔", Adele},
    {"亚克", Ark},
    {"伊利恩", Illium},

    //阿尼玛
    {"虎影", Hoyoung},
    {"菈菈", Lara},

    //其他
    {"神之子", Zero},
    {"凯内西斯", Kinesis},

    //海外职业
    {"阴阳师", Kanna},
    {"剑豪", Hayato},
    {"幻兽师", BeastTamer},
    {"杰特", Jett},
    {"墨玄", MoXuan}
};

#endif // JOB_H
