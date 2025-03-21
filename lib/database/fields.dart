


// get name of any Enum
String strDB(DBFields s) => s.name;

enum DBFields {
  users, // users
  userId,
  name,
  emergencyInfo,
  email,
  userType,
  lastLogin,
  loginCount,
  avatarUrl,
  matches, // matches
  comment,
  isOpen,
  courtNames,
  players,
  parameters, // parameters
  matchDaysToView,
  matchDaysKeeping,
  registerDaysAgoToView,
  registerDaysKeeping,
  fromDaysAgoToTelegram,
  defaultCommentText,
  minDebugLevel,
  weekDaysMatch,
  showLog,
  register, // register
  date,
  registerMessage,
}
