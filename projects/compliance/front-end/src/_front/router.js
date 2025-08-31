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
window.wwg_designInfo = {"id":"8f065f02-e9f8-4493-9078-32a946e675a3","homePageId":"685974f7-5d39-4ec7-8362-d78d319d2b53","authPluginId":"1fa0dd68-5069-436c-9a7d-3b54c340f1fa","baseTag":{},"defaultTheme":"light","langs":[{"lang":"pt","default":true}],"background":{"backgroundImage":null},"workflows":[{"id":"c5fb6e75-7453-41d4-938c-cda4832b4613","name":"run-page-loader","actions":{"7940daf4-7e6d-43d0-b0ea-ca1365999746":{"id":"7940daf4-7e6d-43d0-b0ea-ca1365999746","type":"execute-workflow:99713f38-4596-4ac8-9a64-ddd1a5706536"}},"trigger":"onload-app","description":"Initialize theme state on app load and apply it","firstAction":"7940daf4-7e6d-43d0-b0ea-ca1365999746","firstErrorAction":null}],"pages":[{"id":"e04e6a78-230e-49ba-90c7-0f7d273bbea1","linkId":"e04e6a78-230e-49ba-90c7-0f7d273bbea1","name":"tricket/pagina-dos-produtos","folder":"tricket/","paths":{"pt":"quarentena/tricket/pagina-dos-produtos","default":"quarentena/tricket/pagina-dos-produtos"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"f29013ef-0ea6-4595-ac6c-e78288846cdc","sectionTitle":"marketplace-header","linkId":"dce97a69-e72a-4195-a065-1671aad75449"},{"uid":"ada57b14-e8b8-4457-8c2c-5fd51776cc56","sectionTitle":"main-content","linkId":"40499fdc-1ca3-4c0b-8e67-7badb78894ec"},{"uid":"27d7144c-01dd-4f95-b7cb-f8eefbcc018f","sectionTitle":"marketplace-footer","linkId":"4f837bdb-2334-4bd7-bfaf-bac736601ce9"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"1f675c60-f056-41f5-9af2-f3bb24e63852","linkId":"1f675c60-f056-41f5-9af2-f3bb24e63852","name":"tricket/fornecedor/cadastro/ofertas","folder":"tricket/","paths":{"pt":"tricket/fornecedor/cadastro/ofertas","default":"tricket/fornecedor/cadastro/ofertas"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"a414e03c-cbf1-4086-a801-03a1a9428390","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"3cd3105d-a605-4ec5-ada0-28293e4a481f","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"fe589b5d-a463-4e28-9c09-0ce905af32f3","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"67bbee26-7f79-446e-af1c-4fb7811ab6d4","sectionTitle":"main-content-section","linkId":"ab23804f-1652-4a4e-ab7d-2defe96a0592"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"304131c4-aa64-4f20-9e47-c0e90d5c0d39","linkId":"304131c4-aa64-4f20-9e47-c0e90d5c0d39","name":"_onboarding-cadastro-perfil","folder":null,"paths":{"pt":"cadastro-de-perfil","default":"cadastro-de-perfil"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"8fcf9a95-ed33-43b9-a074-c542f6d1a194","sectionTitle":"header-onboarding","linkId":"9a677ee6-07e2-4074-9562-c99eb9c00a6c"},{"uid":"2197ff3c-5c44-4992-85e1-97e5ea95d79f","sectionTitle":"cadastro-perfil","linkId":"043dc6d0-61f6-4b6d-bb7e-1469959978fc"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"685974f7-5d39-4ec7-8362-d78d319d2b53","linkId":"685974f7-5d39-4ec7-8362-d78d319d2b53","name":"_onboarding-entrar","folder":null,"paths":{"pt":"entrar","default":"entrar"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"802b36f5-ddb4-4bb4-a394-88eb38050d30","sectionTitle":"MAIN-CONTAINER","linkId":"e3217b2a-3360-4f03-a4e0-43245a072e86"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":"images/simbolo-template.svg?_wwcv=8"},{"id":"b1bf3971-ba53-4aa4-b379-a77f4455baac","linkId":"b1bf3971-ba53-4aa4-b379-a77f4455baac","name":"tricket/produto","folder":"tricket/","paths":{"pt":"quarentena/pagina-do-produto/{{offer_id|}}","default":"quarentena/pagina-do-produto/{{offer_id|}}"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"237f3dc2-e27a-4a51-9bd3-4db20a596ea9","sectionTitle":"loader-section","linkId":"677c2da7-cbce-4a41-9499-60e2bc377c42"},{"uid":"f29013ef-0ea6-4595-ac6c-e78288846cdc","sectionTitle":"marketplace-header","linkId":"dce97a69-e72a-4195-a065-1671aad75449"},{"uid":"89a40bfc-bb06-4be6-a119-b55308830711","sectionTitle":"main-content","linkId":"16258308-c601-48f4-b45a-ada0c426e573"},{"uid":"27d7144c-01dd-4f95-b7cb-f8eefbcc018f","sectionTitle":"marketplace-footer","linkId":"4f837bdb-2334-4bd7-bfaf-bac736601ce9"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"5474a688-4b85-4c28-a531-1ad3d520c9ec","linkId":"5474a688-4b85-4c28-a531-1ad3d520c9ec","name":"_onboarding-alterar-senha","folder":null,"paths":{"pt":"nova-senha","default":"nova-senha"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"c77d49f5-1a06-449d-803a-88f05639d9ae","sectionTitle":"main-content","linkId":"35b31e61-b8c3-403d-8e7a-e4567aafc9c4"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"d06b8f4a-e986-4833-98cf-5d4fa1a6c723","linkId":"d06b8f4a-e986-4833-98cf-5d4fa1a6c723","name":"_onboarding-redefinir-senha","folder":null,"paths":{"pt":"recuperar-senha","default":"recuperar-senha"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"9a89e45c-4426-47bf-b19c-144fb5196329","sectionTitle":"main-container","linkId":"0eca836d-cf11-433f-b081-77d65aa61248"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"833f6934-b420-4bae-b5fe-56ed48f6247b","linkId":"833f6934-b420-4bae-b5fe-56ed48f6247b","name":"_onboarding-cadastro","folder":null,"paths":{"pt":"cadastro","default":"cadastro"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"e7f1e784-0bbf-4c49-beab-05573780a4a9","sectionTitle":"MAIN-CONTAINER","linkId":"f0306da7-3448-4e3c-b21e-ce45f944b9e9"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"990f1a2e-0142-40ec-b90d-e1b3ce486f5d","linkId":"990f1a2e-0142-40ec-b90d-e1b3ce486f5d","name":"tricket/admin/cadastros/usuarios","folder":"tricket/","paths":{"pt":"tricket/admin/cadastros/usuarios","default":"tricket/admin/cadastros/usuarios"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"a414e03c-cbf1-4086-a801-03a1a9428390","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"3cd3105d-a605-4ec5-ada0-28293e4a481f","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"fe589b5d-a463-4e28-9c09-0ce905af32f3","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"15d9dc92-baac-46f9-83a4-0d9d2827331b","sectionTitle":"main-content-section","linkId":"3eca58f3-55ad-441e-9fb5-81ce8f5bcca5"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"3fbbed5f-de2d-48d1-8f8b-7b2cb66642e3","linkId":"3fbbed5f-de2d-48d1-8f8b-7b2cb66642e3","name":"compliance/denuncia/empresa","folder":"compliance/","paths":{"pt":"compliance/denuncia/empresa/{{company_slug|}}","default":"compliance/denuncia/empresa/{{company_slug|}}"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"237f3dc2-e27a-4a51-9bd3-4db20a596ea9","sectionTitle":"loader-section","linkId":"677c2da7-cbce-4a41-9499-60e2bc377c42"},{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"ca266487-4c47-4029-8067-510acf171b29","sectionTitle":"Header Section","linkId":"fd5adb0d-d0b5-41c5-9832-e59a655e7de4"},{"uid":"89b4f791-f7bf-4b3c-bc5f-f5561f5eee8c","sectionTitle":"Main Section","linkId":"f4a77ff3-d9a3-428a-b53a-2dbf965fdb10"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"7d9cc4ac-77cf-469e-b666-f67178c679ee","linkId":"7d9cc4ac-77cf-469e-b666-f67178c679ee","name":"tricket-cadastro-oferta","folder":"tricket/","paths":{"pt":"quarentena/oferta-2","default":"quarentena/oferta-2"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"f8d3bd52-7e95-49e5-ae71-2a19667a4e04","sectionTitle":"header-onboarding","linkId":"ebf7a9b8-ca4d-4ee4-8e66-7e376aece62c"},{"uid":"71b666a7-fd67-4f9e-8ee7-708a664fd7be","sectionTitle":"cadastro-perfil","linkId":"7deb15fc-1f84-40dd-8be7-55a6d3223da2"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"190e55b1-94cb-4520-91a3-87f95f5f53ff","linkId":"190e55b1-94cb-4520-91a3-87f95f5f53ff","name":"tricket-marketplace","folder":"tricket/","paths":{"pt":"tricket/marketplace","default":"tricket/marketplace"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"a414e03c-cbf1-4086-a801-03a1a9428390","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"237f3dc2-e27a-4a51-9bd3-4db20a596ea9","sectionTitle":"loader-section","linkId":"677c2da7-cbce-4a41-9499-60e2bc377c42"},{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"f29013ef-0ea6-4595-ac6c-e78288846cdc","sectionTitle":"marketplace-header","linkId":"dce97a69-e72a-4195-a065-1671aad75449"},{"uid":"c171e038-974c-4f0a-9231-aa94bcb1440b","sectionTitle":"marketplace-content","linkId":"805d88bb-049c-4b43-a4b9-953584d5cef8"},{"uid":"27d7144c-01dd-4f95-b7cb-f8eefbcc018f","sectionTitle":"marketplace-footer","linkId":"4f837bdb-2334-4bd7-bfaf-bac736601ce9"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"9b087df3-0b59-45fe-82d5-6d6a92e973bc","linkId":"9b087df3-0b59-45fe-82d5-6d6a92e973bc","name":"compliance/admin/dashboard","folder":"compliance/","paths":{"pt":"compliance/admin/dashboard","default":"compliance/admin/dashboard"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"a414e03c-cbf1-4086-a801-03a1a9428390","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"3cd3105d-a605-4ec5-ada0-28293e4a481f","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"fe589b5d-a463-4e28-9c09-0ce905af32f3","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"43d18b2c-848a-4041-8fbd-2d4af33b1074","sectionTitle":"main-content-section","linkId":"cf066e22-0410-43b7-9b8e-0fa9fbcf54d5"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"ca4ff7e9-6fb3-41af-adfd-c46467cd46fe","linkId":"ca4ff7e9-6fb3-41af-adfd-c46467cd46fe","name":"_onboarding-verificar-celular","folder":null,"paths":{"pt":"verificar-celular","default":"verificar-celular"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"218a5683-5909-4325-bd26-ee4eb45d4360","sectionTitle":"MAIN-CONTAINER","linkId":"b67bd71e-5465-4614-bbe3-c11898e05ec2"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"af5642db-0844-4945-9652-41dc2523f2f5","linkId":"af5642db-0844-4945-9652-41dc2523f2f5","name":"compliance/denuncia/empresa/consultar","folder":"compliance/","paths":{"pt":"{{company_slug|}}","default":"{{company_slug|}}"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"ca266487-4c47-4029-8067-510acf171b29","sectionTitle":"Header Section","linkId":"fd5adb0d-d0b5-41c5-9832-e59a655e7de4"},{"uid":"91dac9ff-ae84-46c6-b6fc-93f41d4caf73","sectionTitle":"Main Section","linkId":"a8ff1eae-6e6e-4297-aea1-ef972136750a"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"f8d580c0-b4d7-43d2-bb81-94671a45d9f1","linkId":"f8d580c0-b4d7-43d2-bb81-94671a45d9f1","name":"compliance/admin/empresas","folder":"compliance/","paths":{"pt":"compliance/admin/empresas","default":"compliance/admin/empresas"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"a414e03c-cbf1-4086-a801-03a1a9428390","sectionTitle":"modal-content-section","linkId":"4daad7a0-984f-40d4-a360-cf52e6eddda7"},{"uid":"3cd3105d-a605-4ec5-ada0-28293e4a481f","sectionTitle":"desktop-header-section","linkId":"be925ad9-6a97-404a-aed1-45b164b9cd40"},{"uid":"fe589b5d-a463-4e28-9c09-0ce905af32f3","sectionTitle":"desktop-sidebar-section","linkId":"e21c02db-7c4b-4c85-a689-10292bcbc63b"},{"uid":"9799c5dc-edad-451b-95f0-dcb43de867e1","sectionTitle":"main-content-section","linkId":"ee35f654-1387-42b0-b41f-59b7702bdad9"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"77d10dbc-1a44-4740-8def-6b1db096ff3e","linkId":"77d10dbc-1a44-4740-8def-6b1db096ff3e","name":"_onboarding-verificar-email","folder":null,"paths":{"pt":"verificar-email/{{user_email|}}","default":"verificar-email/{{user_email|}}"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"181be717-5eb8-4931-b054-a6829a1d5819","sectionTitle":"MAIN-CONTAINER","linkId":"55840529-19d6-422d-b0da-4d76a13c92fd"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"a698a408-8887-47e1-9222-ee1575fe6cb5","linkId":"a698a408-8887-47e1-9222-ee1575fe6cb5","name":"tricket/categorias","folder":"tricket/","paths":{"pt":"quarentena/admin/cadastros/categorias","default":"quarentena/admin/cadastros/categorias"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"a35d6c87-3e9f-44d3-87c4-2cdc21ddf6d4","sectionTitle":"modal-content","linkId":"785cf43d-c2e5-4300-8ef9-3c5f3beeccd2"},{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"b1fd20c1-4967-46cd-b98d-3aab96baa67d","sectionTitle":"Desktop Top Navigation Bar","linkId":"5e815335-d076-4346-9a43-6d3b7d17c419"},{"uid":"6286e722-7e01-4ec6-bee3-658836cd337c","sectionTitle":"Desktop Sidebar","linkId":"4285d7f4-68d8-4fab-912b-f48a18cf0b66"},{"uid":"314beb4b-53ac-4dad-8989-b83ec6179451","sectionTitle":"Mobile Top Navigation","linkId":"9b395d6d-7df3-4f85-92c7-d884e8c196c8"},{"uid":"e6ca6f4a-25cd-4d35-b026-4b246c9636d2","sectionTitle":"Mobile Search Overlay","linkId":"944a679c-a3f4-4d2f-87fb-c6c0d3b6b7f8"},{"uid":"5e9bdfb2-ea77-4992-8fe5-e805aa6a8a2b","sectionTitle":"Mobile Sidebar Section","linkId":"adca30bc-b68d-4c7c-b2f5-d9bc9c4b25d9"},{"uid":"b3dac47e-4cbf-4ef1-a697-007426ad2048","sectionTitle":"Mobile Bottom Navigation","linkId":"0dc4e831-1440-443b-926f-2a8fa4b9b4a8"},{"uid":"84fbf918-a403-4415-aee1-c7b03bf80276","sectionTitle":"Main Content","linkId":"2df51269-3c0e-431f-9572-898819d8015d"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"033b6e87-fd50-4330-8907-8c0aea091435","linkId":"033b6e87-fd50-4330-8907-8c0aea091435","name":"compliance/portal/empresa","folder":"compliance/","paths":{"pt":"compliance/portal/empresa/{{company_slug|}}","default":"compliance/portal/empresa/{{company_slug|}}"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"5eb69b4a-7332-48a0-b32c-7af9ae3ea3eb","sectionTitle":"Header Section","linkId":"16720e47-15ec-4616-916f-8a55ac310dd1"},{"uid":"b1055260-e605-46f0-a803-6855d1686a07","sectionTitle":"Main Section","linkId":"c71e2a37-71ce-4268-b89d-5ea1ae3805b0"},{"uid":"7222e378-1d82-46bf-83ea-672fb4225a71","sectionTitle":"Security Section","linkId":"328639a1-1fba-42ec-b0b7-c6b6daf7e4b8"},{"uid":"b66a4462-e504-4e35-9bb5-26b7944b423c","sectionTitle":"Footer Section","linkId":"75088e3f-0b11-4c2a-b0a2-835b5f0ed50c"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""},{"id":"ff9626f7-1748-48b4-9a24-b1e1d9bab058","linkId":"ff9626f7-1748-48b4-9a24-b1e1d9bab058","name":"_onboarding-status-da-conta","folder":null,"paths":{"pt":"cadastro/status","default":"cadastro/status"},"langs":["pt"],"cmsDataSetPath":null,"sections":[{"uid":"32912bd4-f422-42dc-892d-2c8d2f7c019a","sectionTitle":"bep-messages","linkId":"926e912d-c324-42c7-b341-4b5bf79f8da6"},{"uid":"80ff2a0a-b899-493c-8878-3b59f64defff","sectionTitle":"main-content","linkId":"a2df76ab-b173-40d7-aa0b-df02561535bb"}],"pageUserGroups":[],"title":{},"meta":{"desc":{},"keywords":{},"__typename":"PageMeta","socialDesc":{},"socialTitle":{},"structuredData":{}},"metaImage":""}],"plugins":[{"id":"f9ef41c3-1c53-4857-855b-f2f6a40b7186","name":"Supabase","namespace":"supabase"},{"id":"1fa0dd68-5069-436c-9a7d-3b54c340f1fa","name":"Supabase Auth","namespace":"supabaseAuth"},{"id":"66a79c98-70e7-4bc4-8859-20776b024ec2","name":"PWA","namespace":"pwa"},{"id":"cabb43dd-6161-4140-8ebf-03b6fb045a0b","name":"Google","namespace":"google"},{"id":"97e7b1ae-f88a-4697-849c-ee56ab49bb48","name":"JavaScript","namespace":"javascript"},{"id":"2bd1c688-31c5-443e-ae25-59aa5b6431fb","name":"REST API","namespace":"restApi"}]};
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
