importScripts('https://www.gstatic.com/firebasejs/9.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.14.0/firebase-messaging-compat.js');

// Configuración de Firebase (debe coincidir con la de index.html)
firebase.initializeApp({
    apiKey: "AIzaSyBydFW3DPVO1E8YE3GziH2kWaA57y9ejC0",
    authDomain: "soluva-1abd4.firebaseapp.com",
    projectId: "soluva-1abd4",
    storageBucket: "soluva-1abd4.firebasestorage.app",
    messagingSenderId: "67676164290",
    appId: "1:67676164290:web:58d35ac987693810826b5b",

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
