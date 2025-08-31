import emitter from 'tiny-emitter/instance';
import services from './services/index.js';
import { useIconsStore } from '@/pinia/icons';

 /* wwFront:start */
// eslint-disable-next-line no-undef
import plugin_cabb43dd_6161_4140_8ebf_03b6fb045a0b from '@/components/plugins/plugin-cabb43dd-6161-4140-8ebf-03b6fb045a0b/src/wwPlugin.js';
import plugin_1fa0dd68_5069_436c_9a7d_3b54c340f1fa from '@/components/plugins/plugin-1fa0dd68-5069-436c-9a7d-3b54c340f1fa/src/wwPlugin.js';
import plugin_f9ef41c3_1c53_4857_855b_f2f6a40b7186 from '@/components/plugins/plugin-f9ef41c3-1c53-4857-855b-f2f6a40b7186/src/wwPlugin.js';
import plugin_2bd1c688_31c5_443e_ae25_59aa5b6431fb from '@/components/plugins/plugin-2bd1c688-31c5-443e-ae25-59aa5b6431fb/src/wwPlugin.js';
import plugin_66a79c98_70e7_4bc4_8859_20776b024ec2 from '@/components/plugins/plugin-66a79c98-70e7-4bc4-8859-20776b024ec2/src/wwPlugin.js';
/* wwFront:end */

import { computed, reactive } from 'vue';

export default {
    ...services,
     $on(event, fn) {
        emitter.on(event, fn);
    },
    $once(event, fn) {
        emitter.once(event, fn);
    },
    $emit(event, ...args) {
        if (!event) {
            return;
        }
        emitter.emit(event, ...args);
    },
    $off(event, fn) {
        emitter.off(event, fn);
    },
     front: {},
    $focus: null,
    env: process.env.NODE_ENV,
    async initFront({ router, store }) {
 
        this.front.router = router;
        /* wwFront:start */
        this.$store = store;
        /* wwFront:end */

        //Init services
        this.wwLog.init();

 
        wwLib.logStore.verbose('Starting the application...');
        await this.wwWebsiteData.init();
        this.wwLang.init(router);

        /* wwFront:start */
        // eslint-disable-next-line no-undef
        wwLib.wwPluginHelper.registerPlugin('plugin-cabb43dd-6161-4140-8ebf-03b6fb045a0b', plugin_cabb43dd_6161_4140_8ebf_03b6fb045a0b);
wwLib.wwPluginHelper.registerPlugin('plugin-1fa0dd68-5069-436c-9a7d-3b54c340f1fa', plugin_1fa0dd68_5069_436c_9a7d_3b54c340f1fa);
wwLib.wwPluginHelper.registerPlugin('plugin-f9ef41c3-1c53-4857-855b-f2f6a40b7186', plugin_f9ef41c3_1c53_4857_855b_f2f6a40b7186);
wwLib.wwPluginHelper.registerPlugin('plugin-2bd1c688-31c5-443e-ae25-59aa5b6431fb', plugin_2bd1c688_31c5_443e_ae25_59aa5b6431fb);
wwLib.wwPluginHelper.registerPlugin('plugin-66a79c98-70e7-4bc4-8859-20776b024ec2', plugin_66a79c98_70e7_4bc4_8859_20776b024ec2);
        /* wwFront:end */

 
        services.scrollStore.start();
        services.keyboardEventStore.start();
    },
     // TODO: Verify with Alexis, still uses wwImageMultiLang
    getResponsiveStyleProp({ store, style, uid, states = [], prop }) {
        store = store || wwLib.getFrontWindow().wwLib.$store;
        if (!style && uid) {
            const wwObject = this.$store.getters['websiteData/getWwObjects'][uid];
            if (!wwObject) return '';
            style = (wwObject._state || {}).style || {};
        }

        const screenSizes = store.getters['front/getScreenSizes'];
        const screenSize = store.getters['front/getScreenSize'];

        let value = '';

        for (const media in screenSizes) {
            if (style[media] && typeof style[media][prop] !== 'undefined') {
                value = style[media][prop];
            }
            if (media === screenSize) {
                break;
            }
        }
        for (const state of states) {
            for (const media in screenSizes) {
                if (style[`${state}_${media}`] && style[`${state}_${media}`][prop]) {
                    value = style[`${state}_${media}`][prop];
                }
                if (media === screenSize) {
                    break;
                }
            }
        }

        return value;
    },
    globalContext: reactive({
        page: computed(() => {
            const page = wwLib.$store.getters['websiteData/getPage'];
            if (!page) return {};
            else if (!page.cmsDataSetPath) return { ...pageSanitizer(page) };
            return { ...pageSanitizer(page), data: wwLib.$store.getters['data/getPageCollectionData'] };
        }),
        pageParameters: computed(() => {
            const pageParameters = Object.values(wwLib.$store.getters['data/getPageParameterVariables']);
            const pageParametersValueMap = {};
            for (const pageParameter of pageParameters) pageParametersValueMap[pageParameter.id] = pageParameter.value;
            return pageParametersValueMap;
        }),
        pages: computed(() => {
            const pages = wwLib.$store.getters['websiteData/getPages'];
            const pagesValueMap = {};
            for (const page of pages) pagesValueMap[page.id] = pageSanitizer(page);
            return pagesValueMap;
        }),
        colors: computed(() => {
            const theme = wwLib.$store.getters['front/getTheme'];
             /* wwFront:start */
            // eslint-disable-next-line no-unreachable, no-undef
            return theme === 'dark' ? {"3ddad9d4-1d90-4914-9753-740c2d553f76":"#EDF8EA","04883a16-6149-4d0e-a869-19e16df13663":"#DC3545","fd66c00b-5cd1-429d-b1a2-a241f639c0e5":"#B02A37","6b5ddf34-e6bf-4c87-bc73-0ad8c62c1874":"#FFF8E6","88e735e7-993f-4083-8610-4285637716e1":"#0DCAF0","1e44d022-4014-46bf-baa2-bc7831b3e71e":"#0AA1C0","b2bdb7f2-7bb6-425b-834a-f8d2852d6949":"#4BC033","122c6825-6d0d-4685-a45a-5e2e8c622538":"#3A9828","9f977a98-8728-4b84-817a-34afec233bee":"#FBE9EB","99d85f70-ee6e-41e7-87a5-c7361bb80aac":"#FFC107","b8b27c5f-36a8-4731-97eb-37fae2c5ba46":"#CC9A06","31245f9c-7b57-438f-b5ba-388d79a413c6":"#E7F9FD","885e3a06-b217-48e8-b4bf-5d25a867a5db":"#F4F4F5","701975ce-3a86-47aa-95da-77b9e5cb7cb7":"#27272A","641774cf-fff7-4ae3-915c-76b66befcea1":"#FFFFFF","10d3b92b-ceca-49b7-933b-e28ea5acf92b":"#18181B","3ce9b788-70c0-49b8-9484-0e7a9a24565b":"#18181B","5097f88d-4b8c-4488-a31a-cd069e7120de":"#23838a","c7ebe4af-ff23-4f48-b272-1987a434eee5":"rgba(20, 154, 155, 0.02)","28be1d45-a125-4206-96af-4c971a939ccc":"#1f7278","cd350b4d-9ff5-4bd1-b7d1-a4650304a7a0":"#27272A","03f83b67-c349-4934-9342-6828da1e882d":"#A1A1AA","c69e573c-edf4-49cf-8b5b-8e0a1f609cb0":"#71717A","e53cb414-f823-4aa8-89fc-22b7db9d2888":"#27272A","287651cf-c317-456f-881a-593a4cbad47b":"#3F3F46","9f5c6a83-f71e-45c4-a2ea-b92eecc0f844":"rgba(0, 0, 0, 0.02)","59b28469-6aac-4eab-b870-092cd565f1ae":"#3F3F46","839ca972-b961-4fed-917c-6674a1d6d2dc":"#27272A","548dd09b-4242-4b62-aad7-674898e96942":"#23838a","47fd7441-6ee3-4de0-853a-97a8d6fe5c04":"#3F3F46","d3e4cde7-2d76-4747-8c17-aaa3aea03b73":"#23838a","c9204001-5555-4777-8959-0adb11bd1d9d":"#1a6166","02a7ce6e-f7ae-4460-aa41-9c44597b4998":"#71717A","d327b8de-f1b1-4887-85c8-db7cb22edfb9":"#18181B","fa9e5627-31c0-4d46-ae19-247ed276f68d":"#23838A","1b7d329d-dfb3-409e-8a81-0a095dadb1c9":"#23838A80"} : {"3ddad9d4-1d90-4914-9753-740c2d553f76":"#EDF8EA","04883a16-6149-4d0e-a869-19e16df13663":"#DC3545","fd66c00b-5cd1-429d-b1a2-a241f639c0e5":"#B02A37","6b5ddf34-e6bf-4c87-bc73-0ad8c62c1874":"#FFF8E6","88e735e7-993f-4083-8610-4285637716e1":"#0DCAF0","1e44d022-4014-46bf-baa2-bc7831b3e71e":"#0AA1C0","b2bdb7f2-7bb6-425b-834a-f8d2852d6949":"#4BC033","122c6825-6d0d-4685-a45a-5e2e8c622538":"#3A9828","9f977a98-8728-4b84-817a-34afec233bee":"#FBE9EB","99d85f70-ee6e-41e7-87a5-c7361bb80aac":"#FFC107","b8b27c5f-36a8-4731-97eb-37fae2c5ba46":"#CC9A06","31245f9c-7b57-438f-b5ba-388d79a413c6":"#E7F9FD","885e3a06-b217-48e8-b4bf-5d25a867a5db":"#374151","701975ce-3a86-47aa-95da-77b9e5cb7cb7":"#FFFFFF","641774cf-fff7-4ae3-915c-76b66befcea1":"#FFFFFF","10d3b92b-ceca-49b7-933b-e28ea5acf92b":"#F5F5F5","3ce9b788-70c0-49b8-9484-0e7a9a24565b":"#F3F4F6","5097f88d-4b8c-4488-a31a-cd069e7120de":"#23838a","c7ebe4af-ff23-4f48-b272-1987a434eee5":"rgba(20, 154, 155, 0.01)","28be1d45-a125-4206-96af-4c971a939ccc":"#1f7278","cd350b4d-9ff5-4bd1-b7d1-a4650304a7a0":"#F3F4F6","03f83b67-c349-4934-9342-6828da1e882d":"#6B7280","c69e573c-edf4-49cf-8b5b-8e0a1f609cb0":"#9CA3AF","e53cb414-f823-4aa8-89fc-22b7db9d2888":"#E5E7EB","287651cf-c317-456f-881a-593a4cbad47b":"#D1D5DB","9f5c6a83-f71e-45c4-a2ea-b92eecc0f844":"#282424CC","59b28469-6aac-4eab-b870-092cd565f1ae":"#D1D5DB","839ca972-b961-4fed-917c-6674a1d6d2dc":"#FFFFFF","548dd09b-4242-4b62-aad7-674898e96942":"#23838a","47fd7441-6ee3-4de0-853a-97a8d6fe5c04":"#E5E7EB","d3e4cde7-2d76-4747-8c17-aaa3aea03b73":"#23838a","c9204001-5555-4777-8959-0adb11bd1d9d":"#1a6166","02a7ce6e-f7ae-4460-aa41-9c44597b4998":"#9CA3AF","d327b8de-f1b1-4887-85c8-db7cb22edfb9":"#FFFFFF","fa9e5627-31c0-4d46-ae19-247ed276f68d":"#23838A","1b7d329d-dfb3-409e-8a81-0a095dadb1c9":"#23838A80"};
            /* wwFront:end */
        }),
        spacings:
         /* wwFront:start */
        // eslint-disable-next-line no-unreachable, no-undef
        {"e337c9bd-eb9f-4156-b069-a63fc4f104e1":"42px","8dcd9743-88b5-4c1e-bdf1-d802abe173b2":"36px","1bb43a5b-83d8-49cb-9cee-5d796a25f9a9":"4px","ea2b82a5-8ef3-4de2-bf5e-1c700e7091c4":"80px","7dab9ed3-1bdd-426a-aeb3-1519fb5ccda1":"240px","6b016f05-6cfa-4ea8-9d00-daaec4fa5eea":"240px","0dd71d54-468a-46ea-900e-27d8b4eaef16":"72px"},
        /* wwFront:end */
        typographies:
         /* wwFront:start */
        // eslint-disable-next-line no-unreachable, no-undef
        {"42cb54b8-bb33-48ff-a1f0-90db57fd135e":"500 0.750rem/1.5 'Poppins', sans-serif","245dc89c-13f8-4fe3-bb99-3db2013947f7":"600 0.750rem/1.5 'Poppins', sans-serif","047794a3-e60f-49d9-83b0-cdf120cf2585":"400 0.750rem/1.5 'Poppins', sans-serif","324f7e77-3572-4aa6-9212-c15d18abaa03":"300 0.750rem/1.5 'Poppins', sans-serif","ba428ff5-bf41-4e93-8e68-fa5e8317b016":"600 0.875rem/1.5 'Poppins', sans-serif","6fd9335f-d0d4-4a7c-9b50-80b4a07b3fdf":"500 0.875rem/1.5 'Poppins', sans-serif","c09b65ec-14e9-4db2-bf25-5fdc79e51a44":"600 1.000rem/1.5 'Poppins', sans-serif","997802be-2dd4-4f8c-a6e6-31ef7ba92b30":"400 1.000rem/1.5 'Poppins', sans-serif","7870985d-32ae-4e6a-9017-081642a07139":"400 0.875rem/1.5 'Poppins', sans-serif","1f90a522-c58e-4a32-9c9e-4a6b2d8eddc4":"300 0.875rem/1.5 'Poppins', sans-serif","8d8584d8-62aa-470b-bb9c-1ec819ed9190":"500 1.000rem/1.5 'Poppins', sans-serif","62cfb1cb-05bf-4ecc-b170-aa8741a2db6a":"600 1.953rem/1.4 'Poppins', sans-serif","17b2b2d7-1a51-4fd5-b93a-379492295495":"600 3.815rem/1.2 'Poppins', sans-serif","0e766ec5-1547-4ba0-af02-20368386dc5d":"300 1.000rem/1.5 'Poppins', sans-serif","2af9b7ad-e6f8-439b-87c8-0dfb6deb721e":"600 1.250rem/1.4 'Poppins', sans-serif","518c8e0b-52d5-499d-80d3-bb112416179d":"500 1.250rem/1.4 'Poppins', sans-serif","f4bb1930-2e5a-41dd-9db0-1597e0c59054":"400 1.250rem/1.4 'Poppins', sans-serif","103ebe3c-e2c1-4ca3-bcf9-cae9285bcf0c":"600 1.563rem/1.4 'Poppins', sans-serif","a6fd79af-3479-4ca1-916b-6354fb7ddfd7":"400 1.563rem/1.4 'Poppins', sans-serif","32040a25-becc-49b1-9d89-ea958fc19201":"500 1.563rem/1.4 'Poppins', sans-serif","147512d2-5e7e-4386-bbf8-8fb3b30099fd":"500 1.953rem/1.4 'Poppins', sans-serif","e6af45ac-177b-4c2c-8882-c798ba709629":"400 1.953rem/1.4 'Poppins', sans-serif","cf42bbc3-3b84-4908-a9f1-6acb4f9cbf69":"600 2.441rem/1.3 'Poppins', sans-serif","d7b06a51-8433-4aff-a460-f8a3985f75b9":"500 2.441rem/1.3 'Poppins', sans-serif","2c1a19be-a3ab-401b-98a9-3c79d2ebdc3e":"400 2.441rem/1.3 'Poppins', sans-serif","939ca8f1-f319-4656-85bc-885d0f374e2e":"500 3.052rem/1.2 'Poppins', sans-serif","715ef89f-d0b2-4571-8904-adc3dd43fdc7":"600 3.052rem/1.2 'Poppins', sans-serif","55be398e-be20-4f67-a763-2765d95f401c":"400 3.052rem/1.2 'Poppins', sans-serif","aa4b1f2f-08a9-4d9b-9237-e1556e46feb8":"500 3.815rem/1.2 'Poppins', sans-serif","66ef0cfd-995e-479d-baa3-ac13927e7862":"400 3.815rem/1.2 'Poppins', sans-serif"},
        /* wwFront:end */
        browser: computed(() => {
            const router = wwLib.manager ? wwLib.getEditorRouter() : wwLib.getFrontRouter();
            const currentRoute = router.currentRoute.value;
            let currentQueries = currentRoute.query;
             return {
                url: window.location.origin + currentRoute.fullPath,
                path: currentRoute.path,
                // verify if auth plugin
                 /* wwFront:start */
                // eslint-disable-next-line no-dupe-keys
                source: currentQueries._source,
                /* wwFront:end */
                query: currentQueries,
                domain: window.location.hostname,
                baseUrl: window.location.origin,
                breakpoint: wwLib.$store.getters['front/getScreenSize'],
                environment: wwLib.getEnvironment(),
                theme: wwLib.$store.getters['front/getTheme'],
            };
        }),
        screen: services.scrollStore.screen,
        componentPositionInfo: services.scrollStore.componentPositionInfo,
    }),

    pageData: computed(() => {
        const lang = wwLib.$store.getters['front/getLang'];
        const cmsDataSetPath = wwLib.$store.getters['websiteData/getPage'].cmsDataSetPath;
        if (!cmsDataSetPath) {
            return { lang };
        }

        return { lang, data: wwLib.$store.getters['data/getPageCollectionData'] };
    }),

    getEnvironment() {
        return wwLib.manager
            ? 'editor'
            : window.location.host.includes(
                  // TODO: add staging2 ?
                  '-staging.' + (process.env.WW_ENV === 'staging' ? import.meta.env.VITE_APP_PREVIEW_URL : '')
              )
            ? 'staging'
            : window.location.host.includes(import.meta.env.VITE_APP_PREVIEW_URL)
            ? 'preview'
            : 'production';
    },

    useBaseTag() {
        return (
            wwLib.getEnvironment() === 'production' &&
            window.wwg_designInfo.baseTag &&
            window.wwg_designInfo.baseTag.href
        );
    },

    getBaseTag() {
        let baseTag = window.wwg_designInfo.baseTag?.href || '';
        if (!baseTag.startsWith('/')) {
            baseTag = '/' + baseTag;
        }
        if (!baseTag.endsWith('/')) {
            baseTag += '/';
        }
        return baseTag;
    },

    /**
     * @PUBLIC_API
     */
    getFrontWindow() {
        if (document.querySelector('.ww-manager-iframe')) {
            return document.querySelector('.ww-manager-iframe').contentWindow;
        }
        return window;
    },

    /**
     * @PUBLIC_API
     */
    getFrontDocument() {
        return this.getFrontWindow().document;
    },

    /**
     * @PUBLIC_API
     */
    getFrontRouter() {
        return this.front.router;
    },

    /**
     * @PUBLIC_API
     */
    getEditorWindow() {
         // eslint-disable-next-line no-unreachable
        return null;
    },

    /**
     * @PUBLIC_API
     */
    getEditorDocument() {
         // eslint-disable-next-line no-unreachable
        return null;
    },

    /**
     * @PUBLIC_API
     */
    getEditorRouter() {
        return this.editor.router;
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwApp.goTo
     */
    goTo(...args) {
        wwLib.wwLog.warn('wwLib.goTo is DEPRECATED, use wwLib.wwApp.goTo instead');
        wwLib.wwApp.goTo(...args);
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwUtils.getStyleFromToken
     */
    getStyleFromToken(...args) {
        // wwLib.wwLog.warn('wwLib.getStyleFromToken is DEPRECATED, use wwLib.wwUtils.getStyleFromToken instead');
        return wwLib.wwUtils.getStyleFromToken(...args);
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwUtils.getTypoFromToken
     */
    getTypoFromToken(...args) {
        // wwLib.wwLog.warn('wwLib.getTypoFromToken is DEPRECATED, use wwLib.wwUtils.getTypoFromToken instead');
        return wwLib.wwUtils.getTypoFromToken(...args);
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED
     */
    element(value) {
        wwLib.wwLog.warn('wwLib.element is DEPRECATED');
        if (typeof value === 'object') {
            return { isWwObject: true, ...value };
        } else {
            return { isWwObject: true, type: value };
        }
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwUtils.resolveObjectPropertyPath
     */
    resolveObjectPropertyPath(...args) {
        // wwLib.wwLog.warn(
        //     'wwLib.resolveObjectPropertyPath is DEPRECATED, use wwLib.wwUtils.resolveObjectPropertyPath instead'
        // );
        return wwLib.wwUtils.resolveObjectPropertyPath(...args);
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwutils.getTextStyleFromContent
     */
    getTextStyleFromContent(...args) {
        // wwLib.wwLog.warn(
        //     'wwLib.getTextStyleFromContent is DEPRECATED, use wwLib.wwUtils.getTextStyleFromContent instead'
        // );
        return wwLib.wwUtils.getTextStyleFromContent(...args);
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwWorkflow.executeGlobal
     */
    async executeWorkflow(...args) {
        wwLib.wwLog.warn('wwLib.executeWorkflow is DEPRECATED, use wwLib.wwWorkflow.executeGlobal instead');
        return wwLib.wwWorkflow.executeGlobal(...args);
    },

    /**
     * @PUBLIC_API
     * @EDITOR
     * @DEPRECATED wwLib.wwEditor.findParentUidByFlag
     */
    findParentUidByFlag(...args) {
        wwLib.wwLog.warn('wwLib.wwEditor.findParentUidByFlag is DEPRECATED, use wwLib.findParentUidByFlag instead');
        return wwLib.wwEditor.findParentUidByFlag(...args);
    },

    /**
     * @PUBLIC_API
     * @EDITOR
     * @DEPRECATED wwLib.wwEditor.selectParentByFlag
     */
    selectParentByFlag(...args) {
        wwLib.wwLog.warn('wwLib.wwEditor.selectParentByFlag is DEPRECATED, use wwLib.selectParentByFlag instead');
        return wwLib.wwEditor.selectParentByFlag(...args);
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwElement.useCreate
     */
    useCreateElement() {
        wwLib.wwLog.warn('wwLib.useCreateElement is DEPRECATED, use wwLib.wwElement.useCreate instead');
        return this.wwElement.useCreate();
    },

    /**
     * @PUBLIC_API
     * @DEPRECATED wwLib.wwElement.useLayoutStyle
     */
    useLayoutStyle() {
        wwLib.wwLog.warn('wwLib.useLayoutStyle is DEPRECATED, use wwLib.wwElement.useLayoutStyle instead');
        return wwLib.wwElement.useLayoutStyle();
    },

    /**
     * @PUBLIC_API
     */
    useIcons() {
        const store = useIconsStore();
        return {
            getIcon: store.getIcon,
        };
    },
};

function pageSanitizer(page) {
    const keysToInclude = [
        'id',
        'name',
        'folder',
        'metaImage',
        'pageLoaded',
        'paths',
        'langs',
        'meta',
        'title',
        'sections',
        'pageUserGroups',
    ];

    const _page = {};
    keysToInclude.forEach(key => {
        _page[key] = page[key];
    });

    _page.meta && delete _page.meta.__typename;
    for (const section of _page.sections || []) {
        delete section.__typename;
    }

    const lang = wwLib.$store.getters['front/getLang'];
    if (_page.paths) _page.path = _page.paths[lang] || _page.paths.default;
    else _page.path = null;

    _page.lang = lang;

    return _page;
}
