#include "Character.h"


void Character::updateAttribute()
{
    this->intelligence = this->level * 5 + 8;
    if (level >= 30) this->intelligence += 5;
    if (level >= 60) this->intelligence += 5;
    intelligence += equipment.getIntelligence();
    intelligencePercent = equipment.getIntelligencePercent();
    intelligenceAdd = equipment.getIntelligenceAdd();



    return;
}

