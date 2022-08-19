#ifndef CHARACTER_H
#define CHARACTER_H
#include "Job.h"

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

    //EquipmentSet equipmentSet;
    //Legion legion;
    //Link link;
    //JobBase jobBase;

    void updateAttribute();
};

#endif // CHARACTER_H
