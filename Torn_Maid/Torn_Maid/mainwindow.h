#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <string>
namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:
    Ui::MainWindow *ui;


    std::string mApiKey = "X1r2o88ZhssrxLKP";
};

#endif // MAINWINDOW_H


/*
def query_bazaar_item_price(item_id: int) -> list:
    API_KEY = GET_API_KEY()
    API_BAZZAR_REQUEST_URL = 'https://api.torn.com/market/%d?selections=&key=%s' % (
        item_id, API_KEY)
    items = requests.get(API_BAZZAR_REQUEST_URL).json()['bazaar']
    ret = []
    if items:
        for item in items:
            ret.append((item['cost'], item['quantity']))
    return ret
*/
