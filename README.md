<!--
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-06-24 14:07:51
 * @Description: file content
--> 
# New Launcher

A new launcher powered by Flutter.
After trying some of the launchers, I found they're all lack of effectiveness.
So, I decided to make one own.

The ability new launcher can do:

- [x] Show time and greeting
- [x] Show weather (only by city name now)
- [x] Launch apps
- [ ] Launch useful intents
- [ ] Translate
- [ ] etc

# For Developers
You can make your own [provider] to provide a service in this app. What [provider] can do:
- Produce infomation into the infoList
- Provide some actions for users

Settings will be managed automatically, and when it changes, [provider] will update. So, here are some function to implement:
- provideActions
- initActions
- update