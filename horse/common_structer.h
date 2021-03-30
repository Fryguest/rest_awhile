#ifndef COMMON_STRUCTER_H
#define COMMON_STRUCTER_H


struct Point2d
{
    int x;
    int y;
    Point2d(){x=0;y=0;}
    Point2d(int _x, int _y) {x = _x; y = _y;}
};

struct Point2f
{
    double x;
    double y;
    Point2f(){x=0;y=0;}
    Point2f(double _x, double _y) {x = _x; y = _y;}
};

#endif // COMMON_STRUCTER_H
