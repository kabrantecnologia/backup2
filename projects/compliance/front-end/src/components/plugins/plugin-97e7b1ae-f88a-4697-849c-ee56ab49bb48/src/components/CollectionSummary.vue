<template>
    <div class="javascript-collection-summary">
        <div class="javascript-collection-summary__elem caption-s">JS: {{ config.js || '-' }}</div>
    </div>
</template>

<script>
export default {
    props: {
        config: { type: Object, required: true },
    },
};
</script>

<style lang="scss" scoped>
.javascript-collection-summary {
    &__elem {
        margin-bottom: var(--ww-spacing-01);
    }
}
</style>
