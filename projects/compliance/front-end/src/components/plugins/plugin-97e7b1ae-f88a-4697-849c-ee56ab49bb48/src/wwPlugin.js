
export default {
    /*=============================================m_ÔÔ_m=============================================\
        Collection API
    \================================================================================================*/
    async _fetchCollection(collection) {
        try {
            return {
                data: await eval(`(async () => {${collection.config.js}})()`),
                error: null,
            };
        } catch (err) {
            return { data: null, error: err };
        }
    },
};
