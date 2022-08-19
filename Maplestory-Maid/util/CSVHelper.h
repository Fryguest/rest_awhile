#ifndef CSVHELPER_H
#define CSVHELPER_H

#include <string>
#include <map>
#include <vector>
typedef std::vector<std::map<std::string, std::string>> CSVContent;
typedef std::vector<std::string> CSVLine;
typedef std::map<std::string, std::string> CSVLineWithHeader;

class CSVHelper
{
public:
    static CSVContent LoadFromDisk(const std::string& path);
    static CSVLineWithHeader LineToMap(const std::string& str, const std::vector<std::string>& headers);
    static CSVLine LineToVec(const std::string& str);
};

#endif // CSVHELPER_H
