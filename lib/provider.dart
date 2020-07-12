/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 00:46:55
 * @Description: 
 */

class MyProvider {
  bool updated;
  // a provider means a service
  // func to generate actions without args
  Function initContent;

  // initialization
  MyProvider({
    initContent,
  }) {
    this.updated = false;
    this.initContent = initContent;
  }

  bool needUpdate() {
    if (this.updated == false) {
      return true;
    } else {
      return false;
    }
  }

  void setUpdated() {
    this.updated = true;
  }
}
