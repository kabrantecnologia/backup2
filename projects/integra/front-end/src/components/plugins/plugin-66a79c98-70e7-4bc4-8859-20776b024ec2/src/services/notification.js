export async function showNotification({
    notif_title,
    notif_body,
    notif_icon,
    notif_image,
    notif_tag,
    notif_data,
    notif_vibrate,
    notif_actions,
}) {
    if (!('Notification' in window)) {
        throw new Error('Notifications are not available.');
    }

    try {
        const permission = await Notification.requestPermission();
        if (permission !== 'granted') {
            throw new Error('Notification permission denied.');
        }

        const registration = await navigator.serviceWorker.getRegistration();
        if (registration) {
            const options = {
                body: notif_body,
                icon: notif_icon,
                image: notif_image,
                tag: notif_tag,
                data: notif_data,
                vibrate: notif_vibrate,
                actions: notif_actions,
            };

            registration.showNotification(notif_title, options);
        } else {
            throw new Error('Service Worker registration not found.');
        }
    } catch (error) {
        throw new Error(error, 'Error while sending notification.');
    }
}
