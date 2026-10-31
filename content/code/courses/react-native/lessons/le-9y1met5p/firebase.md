---
title: Push with Firebase directly
version: 1
---

**Expo's service is optional.** An app can register with FCM itself and its server can send through
Firebase Cloud Messaging without Expo in between. Three reasons people do:

- **The backend is already on Firebase or Google Cloud**, and one more service in the path is one more
  thing to watch.
- **Data-only messages**: a push with no visible notification, which wakes the app to sync. That is FCM's
  own form on Android, with every option it has.
- **One token for everything Firebase does**, analytics and in-app messaging included.

The usual library is `@react-native-firebase/messaging`. *What follows is from its documentation and was
not built for this course.* It needs the Firebase project's `google-services.json` and
`GoogleService-Info.plist` in the project, named in `app.json` under `android.googleServicesFile` and
`ios.googleServicesFile`, and its own config plugins. The app asks `messaging().getToken()` for the FCM
token. **On iOS, FCM still goes through APNs**: Firebase forwards the message, using an APNs key uploaded
to the Firebase console. The server sends with the FCM HTTP v1 API, authenticated as a Google service
account.

**The decision is about the server, not the app.** Both roads end in the same notification, the same
handler and the same tap. `expo-notifications` keeps working for the local reminders either way, so the
planner's reminders would not change.
