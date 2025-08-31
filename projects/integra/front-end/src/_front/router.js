import { createRouter, createWebHistory } from 'vue-router';

import wwPage from './views/wwPage.vue';

import { initializeData, initializePlugins, onPageUnload } from '@/_common/helpers/data';

let router;
const routes = [];

function scrollBehavior(to) {
    if (to.hash) {
        return {
            el: to.hash,
            behavior: 'smooth',
        };
    } else {
        return { top: 0 };
    }
}

 
/* wwFront:start */
import pluginsSettings from '../../plugins-settings.json';

// eslint-disable-next-line no-undef
window.wwg_designInfo = {"id":"f338e635-9483-4f9e-852d-bbb54a5e459f","homePageId":"8014af33-ec3c-4671-b6f2-7fc5ee5d4e12","authPluginId":"1fa0dd68-5069-436c-9a7d-3b54c340f1fa","baseTag":{},"defaultTheme":"light","langs":[{"lang":"pt","default":true}],"background":{"backgroundImage":null},"workflows":[{"id":"c5fb6e75-7453-41d4-938c-cda4832b4613","name":"run-page-loader","actions":{"7940daf4-7e6d-43d0-b0ea-ca1365999746":{"id":"7940daf4-7e6d-43d0-b0ea-ca1365999746","type":"execute-workflow:e57d2f88-a659-41de-a9cc-ed030a2f9d92"}},"trigger":"onload-app","description":"Initialize theme state on app load and apply it","firstAction":"7940daf4-7e6d-43d0-b0ea-ca1365999746","firstErrorAction":null}],"pages":[{"id":"7dfb7e68-7419-4a23-acfb-2c34522e07f2","linkId":"7dfb7e68-7419-4a23-acfb-2c34522e07f2","name":"integra/admin/cadastros/pessoas","folder":null,"paths":{"pt":"integra/admin/cadastros/pessoas","default":"integra/admin/cadastros/pessoas"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"d1fccba8-d73d-4b82-8055-2aa8be4cd096","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"cad9e7f4-7777-4336-8621-025166a92e06","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"9595286f-45e3-485e-b6ff-4d5d5cfb3420","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"3ac8c49c-2166-4795-bc0b-9ddbea7e4c5b","sectionTitle":"main-content-section","linkId":"540cff65-fc66-4d38-8a8d-673e2807074b"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"6a546431-ed73-4d01-8ebe-ead474baa7dc","linkId":"6a546431-ed73-4d01-8ebe-ead474baa7dc","name":"integra/crm/campaigns","folder":null,"paths":{"pt":"integra/crm/campaigns","default":"integra/crm/campaigns"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"d1fccba8-d73d-4b82-8055-2aa8be4cd096","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"cad9e7f4-7777-4336-8621-025166a92e06","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"9595286f-45e3-485e-b6ff-4d5d5cfb3420","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"d3b58a3e-0ada-4303-8d1c-8d5dc7bfba49","sectionTitle":"main-content-section","linkId":"c05579a5-39ea-43a0-b40a-df9350a14a18"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"585d8765-6609-4d62-b3df-b5f99009f4b3","linkId":"585d8765-6609-4d62-b3df-b5f99009f4b3","name":"Onboarding Cadastro de Perfil","folder":null,"paths":{"pt":"cadastro-de-perfil","default":"cadastro-de-perfil"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"d378718e-b5d1-449b-92a8-6f0fa25172c6","sectionTitle":"header-onboarding","linkId":"9a677ee6-07e2-4074-9562-c99eb9c00a6c"},{"uid":"6eb82ecf-97d9-4ca0-acdd-d0a651161358","sectionTitle":"cadastro-perfil","linkId":"043dc6d0-61f6-4b6d-bb7e-1469959978fc"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"8014af33-ec3c-4671-b6f2-7fc5ee5d4e12","linkId":"8014af33-ec3c-4671-b6f2-7fc5ee5d4e12","name":"Onboarding Entrar","folder":null,"paths":{"pt":"entrar","default":"entrar"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"1bdb487f-b8bb-4c28-9c22-a0d316581989","sectionTitle":"MAIN-CONTAINER","linkId":"e3217b2a-3360-4f03-a4e0-43245a072e86"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":"images/simbolo-template.svg?_wwcv=8"},{"id":"8fcbfbf7-0aea-4dc7-b779-ca966eb50b90","linkId":"8fcbfbf7-0aea-4dc7-b779-ca966eb50b90","name":"Onboarding Status da Conta","folder":null,"paths":{"pt":"cadastro/status","default":"cadastro/status"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"67fee24e-8e7f-44ec-9a52-f76a246b14bf","sectionTitle":"main-content","linkId":"a2df76ab-b173-40d7-aa0b-df02561535bb"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"6fe4ea05-3edb-4114-bb38-1bb56d250cdb","linkId":"6fe4ea05-3edb-4114-bb38-1bb56d250cdb","name":"chat","folder":"_Settings/","paths":{"pt":"chat","default":"chat"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"fbee5f9d-d580-4aac-a5e1-1cd6ca91e085","sectionTitle":"Section","linkId":"b04ce542-ba67-483f-a9fd-14baee0e1b13"},{"uid":"f03f3a15-63b6-47c8-9256-9b98a1f20326","sectionTitle":"Content","linkId":"677ff15e-7e5e-4a2f-9c76-d868ea3bc158"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"e29e4f7f-8aea-4e10-b092-d74924c6a860","linkId":"e29e4f7f-8aea-4e10-b092-d74924c6a860","name":"kanban","folder":"_Settings/","paths":{"pt":"kanban","default":"kanban"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"481e8c6c-0602-48ab-9aac-559fd59e7ef7","sectionTitle":"Section","linkId":"defd3062-703a-46a9-893c-78d89a623510"},{"uid":"3fe319c0-6f1e-458e-88c1-3cb53f9dd158","sectionTitle":"Content","linkId":"249c1227-45ad-4943-9f9d-25922b1b9af0"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"3dbb779e-e927-4e70-8a1b-d24b174c6a0f","linkId":"3dbb779e-e927-4e70-8a1b-d24b174c6a0f","name":"Onboarding Alterar Senha","folder":null,"paths":{"pt":"nova-senha","default":"nova-senha"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"9eaa2183-0f34-41c2-9f95-acdb8a573091","sectionTitle":"main-content","linkId":"35b31e61-b8c3-403d-8e7a-e4567aafc9c4"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"fcda4035-60d5-4e88-bfcf-b994d65c6a09","linkId":"fcda4035-60d5-4e88-bfcf-b994d65c6a09","name":"Onboarding Redefinir Senha","folder":null,"paths":{"pt":"recuperar-senha","default":"recuperar-senha"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"e941fdc7-8415-4b6b-8baa-04ad9aa481bf","sectionTitle":"main-container","linkId":"0eca836d-cf11-433f-b081-77d65aa61248"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"3e631ab5-b46d-41f3-89fd-4e498faeca42","linkId":"3e631ab5-b46d-41f3-89fd-4e498faeca42","name":"Icons","folder":"_Settings/","paths":{"pt":"icons","default":"icons"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"a49962e0-5f36-46c6-a0e0-c3ea2a46b6ac","sectionTitle":"Header Section","linkId":"38653128-2b09-48ad-b32e-1872966e48c4"},{"uid":"9af0c982-8e14-411b-a5de-f60ab5f301b6","sectionTitle":"Icons Grid Section","linkId":"b8c203ee-245b-4135-a14e-b7f29587c9c8"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"f5fb81a6-631b-40ea-9a0b-60de9cae704a","linkId":"f5fb81a6-631b-40ea-9a0b-60de9cae704a","name":"Emails","folder":"_Settings/","paths":{"pt":"emails","default":"emails"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"e21fe244-1716-4911-ad51-69302a7d7423","sectionTitle":"Email Panel Section","linkId":"225dec56-4134-4865-ad9d-f3442041e7e6"},{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"57cfe0b0-bff4-46c5-a303-6576de14cedb","sectionTitle":"Desktop Top Navigation Bar","linkId":"5e815335-d076-4346-9a43-6d3b7d17c419"},{"uid":"e7d8759a-2620-498d-adae-7027ba800749","sectionTitle":"Desktop Sidebar","linkId":"4285d7f4-68d8-4fab-912b-f48a18cf0b66"},{"uid":"8907a06d-ed8c-43db-ab5b-b5f6ad8faafc","sectionTitle":"Desktop Footer","linkId":"cf40bb6a-b5b4-49d3-bab7-81ea4732b72b"},{"uid":"9848d000-7fa3-4b1f-9ab5-d558e764676e","sectionTitle":"Mobile Top Navigation","linkId":"9b395d6d-7df3-4f85-92c7-d884e8c196c8"},{"uid":"23e9266a-49db-4267-94e6-5ab1ff09aa02","sectionTitle":"Mobile Search Overlay","linkId":"944a679c-a3f4-4d2f-87fb-c6c0d3b6b7f8"},{"uid":"873464f7-0cbe-47d6-ae37-749e18422023","sectionTitle":"Mobile Sidebar Section","linkId":"adca30bc-b68d-4c7c-b2f5-d9bc9c4b25d9"},{"uid":"7f2fafb1-fa36-4c3b-a938-2fb4ec68bebf","sectionTitle":"Mobile Bottom Navigation","linkId":"0dc4e831-1440-443b-926f-2a8fa4b9b4a8"},{"uid":"73c0124a-9aed-4482-89d2-93daf5e8cfcd","sectionTitle":"Main Content","linkId":"d181ac6c-4dff-4a6c-b70e-aeee0c3c9546"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"2ab1889b-3dc4-459a-89c7-66503d54be6b","linkId":"2ab1889b-3dc4-459a-89c7-66503d54be6b","name":"Design System","folder":"_Settings/","paths":{"pt":"design-system","default":"design-system"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"57cfe0b0-bff4-46c5-a303-6576de14cedb","sectionTitle":"Desktop Top Navigation Bar","linkId":"5e815335-d076-4346-9a43-6d3b7d17c419"},{"uid":"7967546c-1d04-44fd-9fd2-2208f6dd4913","sectionTitle":"Desktop Sidebar","linkId":"cf9da727-53f1-4dfa-84aa-deb373bb0f2f"},{"uid":"9848d000-7fa3-4b1f-9ab5-d558e764676e","sectionTitle":"Mobile Top Navigation","linkId":"9b395d6d-7df3-4f85-92c7-d884e8c196c8"},{"uid":"23e9266a-49db-4267-94e6-5ab1ff09aa02","sectionTitle":"Mobile Search Overlay","linkId":"944a679c-a3f4-4d2f-87fb-c6c0d3b6b7f8"},{"uid":"873464f7-0cbe-47d6-ae37-749e18422023","sectionTitle":"Mobile Sidebar Section","linkId":"adca30bc-b68d-4c7c-b2f5-d9bc9c4b25d9"},{"uid":"7f2fafb1-fa36-4c3b-a938-2fb4ec68bebf","sectionTitle":"Mobile Bottom Navigation","linkId":"0dc4e831-1440-443b-926f-2a8fa4b9b4a8"},{"uid":"5b513040-0912-4d94-ab1a-e1895f601542","sectionTitle":"main-content","linkId":"3cf89b43-a858-498f-81bf-4334fe08cdc5"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"00b8e885-1595-41b0-8439-c58ffe9925bb","linkId":"00b8e885-1595-41b0-8439-c58ffe9925bb","name":"Onboarding Verificar Email","folder":null,"paths":{"pt":"verificar-email/{{user_email|}}","default":"verificar-email/{{user_email|}}"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"555e6f47-63b0-4e6d-9e6c-e4e4dd240444","sectionTitle":"BEP-MESSAGES","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"5813f7f4-1531-4971-89a1-1240a55db29b","sectionTitle":"MAIN-CONTAINER","linkId":"55840529-19d6-422d-b0da-4d76a13c92fd"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"e7947210-4781-46ab-a84b-6148dabc0915","linkId":"e7947210-4781-46ab-a84b-6148dabc0915","name":"Integra Admin Dashboard","folder":null,"paths":{"pt":"integra/admin/dashboard","default":"integra/admin/dashboard"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"d1fccba8-d73d-4b82-8055-2aa8be4cd096","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"cad9e7f4-7777-4336-8621-025166a92e06","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"9595286f-45e3-485e-b6ff-4d5d5cfb3420","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"5759ee8b-ce93-4782-a8b3-474d6fc8cb59","sectionTitle":"main-content-section","linkId":"dfa5f047-1518-455f-9424-48e2f7c9dc6e"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"169c77ea-c514-421c-921b-0bf85a4c49dd","linkId":"169c77ea-c514-421c-921b-0bf85a4c49dd","name":"Integra Admin Cadastro Usuários","folder":null,"paths":{"pt":"integra/admin/cadastros/usuarios","default":"integra/admin/cadastros/usuarios"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"d1fccba8-d73d-4b82-8055-2aa8be4cd096","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"cad9e7f4-7777-4336-8621-025166a92e06","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"9595286f-45e3-485e-b6ff-4d5d5cfb3420","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"b23272fc-1098-44fc-8906-d9514b14f67e","sectionTitle":"main-content-section","linkId":"c5f1d672-b086-4ae8-ab4b-2baa274b0d63"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"e459a3de-be91-4304-8cda-44e178c4b550","linkId":"e459a3de-be91-4304-8cda-44e178c4b550","name":"Integra Admin Cadastro Departamentos","folder":null,"paths":{"pt":"integra/admin/cadastros/departamentos","default":"integra/admin/cadastros/departamentos"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"d1fccba8-d73d-4b82-8055-2aa8be4cd096","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"cad9e7f4-7777-4336-8621-025166a92e06","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"9595286f-45e3-485e-b6ff-4d5d5cfb3420","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"5e8f7523-e270-4c99-b2f1-5a5778fe3c26","sectionTitle":"main-content-section","linkId":"019930f2-e346-40b4-a9c8-9d16e681b2a3"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"1e36cd17-034b-4089-a484-1491bf9d9a5a","linkId":"1e36cd17-034b-4089-a484-1491bf9d9a5a","name":"integra/admin/cadastros/funcionarios","folder":null,"paths":{"pt":"integra/admin/cadastros/funcionarios","default":"integra/admin/cadastros/funcionarios"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"d1fccba8-d73d-4b82-8055-2aa8be4cd096","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"cad9e7f4-7777-4336-8621-025166a92e06","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"9595286f-45e3-485e-b6ff-4d5d5cfb3420","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"31e8333b-346d-4b10-8b05-2cea4436d2d6","sectionTitle":"main-content-section","linkId":"9531d40e-aa1b-47f5-8e33-7dc0a4b7e808"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""}],"plugins":[{"id":"f9ef41c3-1c53-4857-855b-f2f6a40b7186","name":"Supabase","namespace":"supabase"},{"id":"1fa0dd68-5069-436c-9a7d-3b54c340f1fa","name":"Supabase Auth","namespace":"supabaseAuth"},{"id":"66a79c98-70e7-4bc4-8859-20776b024ec2","name":"PWA","namespace":"pwa"},{"id":"cabb43dd-6161-4140-8ebf-03b6fb045a0b","name":"Google","namespace":"google"},{"id":"2bd1c688-31c5-443e-ae25-59aa5b6431fb","name":"REST API","namespace":"restApi"}]};
// eslint-disable-next-line no-undef
window.wwg_cacheVersion = 8;
// eslint-disable-next-line no-undef
window.wwg_pluginsSettings = pluginsSettings;
// eslint-disable-next-line no-undef
window.wwg_disableManifest = false;

const defaultLang = window.wwg_designInfo.langs.find(({ default: isDefault }) => isDefault) || {};

const registerRoute = (page, lang, forcedPath) => {
    const langSlug = !lang.default || lang.isDefaultPath ? `/${lang.lang}` : '';
    let path =
        forcedPath ||
        (page.id === window.wwg_designInfo.homePageId ? '/' : `/${page.paths[lang.lang] || page.paths.default}`);

    //Replace params
    path = path.replace(/{{([\w]+)\|([^/]+)?}}/g, ':$1');

    routes.push({
        path: langSlug + path,
        component: wwPage,
        name: `page-${page.id}-${lang.lang}`,
        meta: {
            pageId: page.id,
            lang,
            isPrivate: !!page.pageUserGroups?.length,
        },
        async beforeEnter(to, from) {
            if (to.name === from.name) return;
            //Set page lang
            wwLib.wwLang.defaultLang = defaultLang.lang;
            wwLib.$store.dispatch('front/setLang', lang.lang);

            //Init plugins
            await initializePlugins();

            //Check if private page
            if (page.pageUserGroups?.length) {
                // cancel navigation if no plugin
                if (!wwLib.wwAuth.plugin) {
                    return false;
                }

                await wwLib.wwAuth.init();

                // Redirect to not sign in page if not logged
                if (!wwLib.wwAuth.getIsAuthenticated()) {
                    window.location.href = `${wwLib.wwPageHelper.getPagePath(
                        wwLib.wwAuth.getUnauthenticatedPageId()
                    )}?_source=${to.path}`;

                    return null;
                }

                //Check roles are required
                if (
                    page.pageUserGroups.length > 1 &&
                    !wwLib.wwAuth.matchUserGroups(page.pageUserGroups.map(({ userGroup }) => userGroup))
                ) {
                    window.location.href = `${wwLib.wwPageHelper.getPagePath(
                        wwLib.wwAuth.getUnauthorizedPageId()
                    )}?_source=${to.path}`;

                    return null;
                }
            }

            try {
                await import(`@/pages/${page.id.split('_')[0]}.js`);
                await wwLib.wwWebsiteData.fetchPage(page.id);

                //Scroll to section or on top after page change
                if (to.hash) {
                    const targetElement = document.getElementById(to.hash.replace('#', ''));
                    if (targetElement) targetElement.scrollIntoView();
                } else {
                    document.body.scrollTop = document.documentElement.scrollTop = 0;
                }

                return;
            } catch (err) {
                wwLib.$store.dispatch('front/showPageLoadProgress', false);

                if (err.redirectUrl) {
                    return { path: err.redirectUrl || '404' };
                } else {
                    //Any other error: go to target page using window.location
                    window.location = to.fullPath;
                }
            }
        },
    });
};

for (const page of window.wwg_designInfo.pages) {
    for (const lang of window.wwg_designInfo.langs) {
        if (!page.langs.includes(lang.lang)) continue;
        registerRoute(page, lang);
    }
}

const page404 = window.wwg_designInfo.pages.find(page => page.paths.default === '404');
if (page404) {
    for (const lang of window.wwg_designInfo.langs) {
        // Create routes /:lang/:pathMatch(.*)* etc for all langs of the 404 page
        if (!page404.langs.includes(lang.lang)) continue;
        registerRoute(
            page404,
            {
                default: false,
                lang: lang.lang,
            },
            '/:pathMatch(.*)*'
        );
    }
    // Create route /:pathMatch(.*)* using default project lang
    registerRoute(page404, { default: true, isDefaultPath: false, lang: defaultLang.lang }, '/:pathMatch(.*)*');
} else {
    routes.push({
        path: '/:pathMatch(.*)*',
        async beforeEnter() {
            window.location.href = '/404';
        },
    });
}

let routerOptions = {};

const isProd =
    !window.location.host.includes(
        // TODO: add staging2 ?
        '-staging.' + (process.env.WW_ENV === 'staging' ? import.meta.env.VITE_APP_PREVIEW_URL : '')
    ) && !window.location.host.includes(import.meta.env.VITE_APP_PREVIEW_URL);

if (isProd && window.wwg_designInfo.baseTag?.href) {
    let baseTag = window.wwg_designInfo.baseTag.href;
    if (!baseTag.startsWith('/')) {
        baseTag = '/' + baseTag;
    }
    if (!baseTag.endsWith('/')) {
        baseTag += '/';
    }

    routerOptions = {
        base: baseTag,
        history: createWebHistory(baseTag),
        routes,
    };
} else {
    routerOptions = {
        history: createWebHistory(),
        routes,
    };
}

router = createRouter({
    ...routerOptions,
    scrollBehavior,
});

//Trigger on page unload
let isFirstNavigation = true;
router.beforeEach(async (to, from) => {
    if (to.name === from.name) return;
    if (!isFirstNavigation) await onPageUnload();
    isFirstNavigation = false;
    wwLib.globalVariables._navigationId++;
    return;
});

//Init page
router.afterEach((to, from, failure) => {
    wwLib.$store.dispatch('front/showPageLoadProgress', false);
    let fromPath = from.path;
    let toPath = to.path;
    if (!fromPath.endsWith('/')) fromPath = fromPath + '/';
    if (!toPath.endsWith('/')) toPath = toPath + '/';
    if (failure || (from.name && toPath === fromPath)) return;
    initializeData(to);
});
/* wwFront:end */

export default router;
