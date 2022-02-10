#ifndef FORMULA_H
#define FORMULA_H

#include<vector>

struct Formula
{
    int production;//产物Id， 当前不考虑多产物的情况
    int productNum;//每次生产的数量
    std::vector<int> materialList; //材料列表
    double dpm; //每分钟制作次数
    Formula(int _production, int _productNum, std::vector<int> _materialList, double _dpm)
    {
        production = _production;
        productNum = _productNum;
        materialList = _materialList;
        dpm = _dpm;
    }
};

#endif // FORMULA_H
