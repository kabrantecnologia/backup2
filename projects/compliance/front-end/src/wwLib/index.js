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
import plugin_97e7b1ae_f88a_4697_849c_ee56ab49bb48 from '@/components/plugins/plugin-97e7b1ae-f88a-4697-849c-ee56ab49bb48/src/wwPlugin.js';
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
wwLib.wwPluginHelper.registerPlugin('plugin-97e7b1ae-f88a-4697-849c-ee56ab49bb48', plugin_97e7b1ae_f88a_4697_849c_ee56ab49bb48);
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
            return theme === 'dark' ? {"5485a9d3-a98e-43ad-8f82-2b5df8b70c82":"#000","eb22ce53-a99b-4ece-8563-94341d375b64":"#1A1A1A","9808f6b0-ab04-4561-a915-bffbb987a118":"#333333","0102b5e0-e821-436b-9be2-e7415e2cfdca":"#4D4D4D","e7006600-52d9-4cd9-9151-a3d7567b7506":"#666666","bc47e525-5fe5-4ed7-a3fd-9a3bc6989cac":"#808080","8d5fc3af-e59f-44f1-a6d5-9127a2ab053d":"#999999","1247c1f2-dfb0-4e0c-b7c8-cafd832ca887":"#B3B3B3","7bbd72da-5ba3-4902-955f-1e7088f60584":"#CCCCCC","cde87955-f658-47d9-8962-af99bf64f433":"#E6E6E6","d5de3e13-05e2-4080-92d9-85f1364e91b6":"#F2F2F2","72608f0c-cbce-449a-affa-5c81c72e9469":"#FFFFFF","1739624f-9d37-4017-9160-8c2e30b48750":"#02983E","3f4780e1-cde2-4569-87bb-e306b098cd65":"#4FD484","eaafe37e-42e5-4bf7-a460-48aead219cad":"#D3F4E0","f7657c81-57b8-419d-8bfc-8d90de4d8b7e":"#FF0000","0256b8f5-bd96-495d-bb59-cc4ae15210c4":"#FF4D4D","f43ce813-809a-46ba-8e5d-38c246437e5a":"#FF9999","ac29aa49-faf4-493b-be8d-462981a9e67e":"#FFC107","5d5467e1-fb70-41a7-9dec-d0f60d89f5ce":"#FFD966","c3e3b667-be45-47d9-9a07-880b31b0ff7c":"#FFF299","364dc12c-118e-48b8-97db-ce389fbba540":"#0077B6","bca785a4-a37c-4208-9a44-8f27fa55cd6a":"#3399CC","713b9306-0b79-4c5e-b671-c5518ed3a3da":"#66B3FF","60c6d661-5f3b-4387-bbb9-932631d14bc6":"#022b33","5a15f7b8-8072-4e59-907c-daba30019e25":"#4bc033"} : {"5485a9d3-a98e-43ad-8f82-2b5df8b70c82":"#000","eb22ce53-a99b-4ece-8563-94341d375b64":"#1A1A1A","9808f6b0-ab04-4561-a915-bffbb987a118":"#333333","0102b5e0-e821-436b-9be2-e7415e2cfdca":"#4D4D4D","e7006600-52d9-4cd9-9151-a3d7567b7506":"#666666","bc47e525-5fe5-4ed7-a3fd-9a3bc6989cac":"#808080","8d5fc3af-e59f-44f1-a6d5-9127a2ab053d":"#999999","1247c1f2-dfb0-4e0c-b7c8-cafd832ca887":"#B3B3B3","7bbd72da-5ba3-4902-955f-1e7088f60584":"#CCCCCC","cde87955-f658-47d9-8962-af99bf64f433":"#E6E6E6","d5de3e13-05e2-4080-92d9-85f1364e91b6":"#F2F2F2","72608f0c-cbce-449a-affa-5c81c72e9469":"#FFFFFF","1739624f-9d37-4017-9160-8c2e30b48750":"#02983E","3f4780e1-cde2-4569-87bb-e306b098cd65":"#4FD484","eaafe37e-42e5-4bf7-a460-48aead219cad":"#D3F4E0","f7657c81-57b8-419d-8bfc-8d90de4d8b7e":"#FF0000","0256b8f5-bd96-495d-bb59-cc4ae15210c4":"#FF4D4D","f43ce813-809a-46ba-8e5d-38c246437e5a":"#FF9999","ac29aa49-faf4-493b-be8d-462981a9e67e":"#FFC107","5d5467e1-fb70-41a7-9dec-d0f60d89f5ce":"#FFD966","c3e3b667-be45-47d9-9a07-880b31b0ff7c":"#FFF299","364dc12c-118e-48b8-97db-ce389fbba540":"#0077B6","bca785a4-a37c-4208-9a44-8f27fa55cd6a":"#3399CC","713b9306-0b79-4c5e-b671-c5518ed3a3da":"#66B3FF","60c6d661-5f3b-4387-bbb9-932631d14bc6":"#022b33","5a15f7b8-8072-4e59-907c-daba30019e25":"#4bc033"};
            /* wwFront:end */
        }),
        spacings:
         /* wwFront:start */
        // eslint-disable-next-line no-unreachable, no-undef
        {"4cb2b291-01b9-4caf-9211-50ab231a10cd":"42px","4b2e326d-b760-4002-acd8-7d5d9659bb63":"36px","394c9f09-22fe-40ed-b332-887f48c9d59e":"4px","1d23199a-a456-440a-9dd1-cce8b269b0c6":"80px","e95e3caf-6ca5-43ba-990f-04640fab2265":"240px","896a0001-d0f9-43dd-ba5f-faa5a17bc2be":"240px","23c0db7c-b861-4d19-8e5b-60a7f8d024d3":"72px","50501488-fa48-420c-8363-f573b687e709":"36px","9cecca9f-33d6-4af3-a5a8-fec863cd8bc3":"4px"},
        /* wwFront:end */
        typographies:
         /* wwFront:start */
        // eslint-disable-next-line no-unreachable, no-undef
        {"c146f915-916a-4907-92c0-620ecc502d29":"500 0.750rem/1.5 'Poppins', sans-serif","e6a0ae99-7ab4-4338-839d-1d1ffdaa4728":"600 0.750rem/1.5 'Poppins', sans-serif","108b1354-88ac-4f1a-8478-5ffba683d86f":"400 0.750rem/1.5 'Poppins', sans-serif","07453ca3-a03a-4495-8fb5-aa3b5ef1584a":"300 0.750rem/1.5 'Poppins', sans-serif","d0fe69f0-decf-4cb0-ad08-629995e2c601":"600 0.875rem/1.5 'Poppins', sans-serif","e4a68725-a11c-4b3f-9236-da1a56283e04":"500 0.875rem/1.5 'Poppins', sans-serif","6d702126-4b55-4569-b530-8227f389ecb8":"600 1.000rem/1.5 'Poppins', sans-serif","2bcaa23c-ecfb-4840-96c7-c6cb3b4f436d":"400 1.000rem/1.5 'Poppins', sans-serif","a00b6e09-511a-4757-9fb5-eb73d73c28a6":"400 0.875rem/1.5 'Poppins', sans-serif","6d23ec8a-7a9b-4f57-9415-2ece2176ec4b":"300 0.875rem/1.5 'Poppins', sans-serif","0e896f83-da43-416a-bf9c-a058412d00e3":"500 1.000rem/1.5 'Poppins', sans-serif","125a7a0d-5789-48f1-be40-9ee993b3b7d4":"600 1.953rem/1.4 'Poppins', sans-serif","a68cfcd5-bc64-4bbb-9d72-ea76c66fb8bf":"600 3.815rem/1.2 'Poppins', sans-serif","4af482ff-12ac-4c57-b452-b703ecfcde66":"300 1.000rem/1.5 'Poppins', sans-serif","4c28b18d-c1f2-488a-99ba-5aeff8a3e84a":"600 1.250rem/1.4 'Poppins', sans-serif","e3c90d3e-bb5d-4528-9f52-d5002439efc0":"500 1.250rem/1.4 'Poppins', sans-serif","c48f54f6-c509-4e8a-9cb9-66f5cb14a66c":"400 1.250rem/1.4 'Poppins', sans-serif","d522b72d-14f7-454c-8f19-53aef7adf7d5":"600 1.563rem/1.4 'Poppins', sans-serif","ae7a79d9-4962-437e-abc3-cc99da893ef3":"400 1.563rem/1.4 'Poppins', sans-serif","ace55933-ad1c-4b14-bc02-db6542b9ae16":"500 1.563rem/1.4 'Poppins', sans-serif","05854847-5fff-483a-a4ef-03a74a5fd012":"500 1.953rem/1.4 'Poppins', sans-serif","dcdea4d5-2bc6-47e5-a47a-6d3e4e469c15":"400 1.953rem/1.4 'Poppins', sans-serif","3f0aaca0-2185-4cda-afd4-e3943703c0fd":"600 2.441rem/1.3 'Poppins', sans-serif","97a87d14-83b1-4b04-8fd4-a066008a702a":"500 2.441rem/1.3 'Poppins', sans-serif","635b688c-ec26-461c-a336-afffdceac51b":"400 2.441rem/1.3 'Poppins', sans-serif","9259adb9-c82f-450e-84d2-5693180b51dd":"500 3.052rem/1.2 'Poppins', sans-serif","49bd0052-ce8c-466b-bee6-0e0665fdc451":"600 3.052rem/1.2 'Poppins', sans-serif","b8940e21-54d8-477a-8395-581ef2eff4c3":"400 3.052rem/1.2 'Poppins', sans-serif","ba835de7-50ad-4fdc-b707-f13d5949996a":"500 3.815rem/1.2 'Poppins', sans-serif","437d6a3a-d12c-4cc8-82f2-7141d192a79e":"400 3.815rem/1.2 'Poppins', sans-serif"},
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
