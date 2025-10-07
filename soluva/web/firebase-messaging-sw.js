importScripts('https://www.gstatic.com/firebasejs/9.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.14.0/firebase-messaging-compat.js');

// Configuración de Firebase (debe coincidir con la de index.html)
firebase.initializeApp({
    apiKey: "AIzaSyCF1JXi_z9kLbIOcthLSzZOeFab-lc5RN0",
    authDomain: "solluvanotifications.firebaseapp.com",
    projectId: "solluvanotifications",
    storageBucket: "solluvanotifications.firebasestorage.app",
    messagingSenderId: "296702582098",
    appId: "1:296702582098:web:0f3716684c19b577bcee8b",

});

const messaging = firebase.messaging();


messaging.onBackgroundMessage(function (payload) {
    console.log("Notificación en background:", payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
    };
    self.registration.showNotification(notificationTitle, notificationOptions);
});
