#ifndef CHARACTER_H
#define CHARACTER_H

enum Job
{
    主教,
    大魔导师（火，毒）,
    大魔导师（冰，雷）
};


class Character
{
    int level;
    Job job;

    int strength;
    int strengthPercent;
    int strengthAdd;

    int dexterity;
    int dexterityPercent;
    int dexterityAdd;

    int intelligence;
    int intelligencePercent;
    int intelligenceAdd;

    int luck;
    int luckPercent;
    int luckAdd;

    int attack;
    int attackPercent;
    int magicAttack;
    int magicAttackPercent;

    int damage;
    int bossDamage;
    int finalDamage;
    int ignoreDefense;

    Equipment equipment;

    void updateAttribute();
};

#endif // CHARACTER_H
