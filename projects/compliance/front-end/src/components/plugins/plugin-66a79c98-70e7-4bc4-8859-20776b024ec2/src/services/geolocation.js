export async function geolocation() {
    if (!('geolocation' in navigator)) {
        throw new Error('Geolocation is not available.');
    }

    try {
        const response = await new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject);
        });

        return {
            coords: {
                accuracy: response.coords.accuracy,
                altitude: response.coords.altitude,
                altitudeAccurary: response.coords.altitudeAccurary,
                heading: response.coords.heading,
                latitude: response.coords.latitude,
                longitude: response.coords.longitude,
                speed: response.coords.speed,
            },
            timestamp: response.timestamp,
        };
    } catch (error) {
        throw new Error(error, 'Error while geolocation.');
    }
}
