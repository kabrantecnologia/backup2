export async function share({ share_title, share_text, share_url }) {
    if (!('share' in navigator)) {
        throw new Error('Share is not available.');
    }

    try {
        const shareData = {
            title: share_title,
            text: share_text,
            url: share_url,
        };

        if (navigator.canShare && navigator.canShare(shareData)) {
            await navigator.share(shareData);
        } else {
            throw new Error('Data cannot be shared.');
        }
    } catch (error) {
        throw new Error(error, 'Error while sharing.');
    }
}
