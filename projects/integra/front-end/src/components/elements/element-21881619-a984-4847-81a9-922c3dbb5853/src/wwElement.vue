<template>
    <component
        :is="tag"
        v-bind="properties"
        class="ww-columns"
        :class="{ editing: wwEditorState?.canBeEdited, empty: isEmpty, '-link': hasLink && !isEditing }"
    >
        <wwLayout
            class="ww-columns__dropzone"
            path="children"
            :direction="direction"
            :style="layoutStyle"
            ww-responsive="wwLayout"
            @update:list="update"
        >
            <template #default="{ item, index }">
                <div
                    class="ww-columns__column"
                    :ww-responsive="`index-${index}`"
                    :class="[
                        {
                            editing: wwEditorState?.canBeEdited,
                            draging: dragingIndex === index,
                        },
                    ]"
                    :style="getItemStyle(index)"
                >
                    <wwElement
                        v-bind="item"
                        class="ww-columns__object"
                        :extra-style="wwObjectFlex"
                        :ww-responsive="`wwobject-${index}`"
                    ></wwElement>

                </div>
            </template>
        </wwLayout>
    </component>
</template>

<script>
export default {
    props: {
        content: { type: Object, required: true },
        wwFrontState: { type: Object, required: true },
    },
    emits: ['update:content', 'update:content:effect'],
    setup() {
        const { hasLink, tag: linkTag, properties } = wwLib.wwElement.useLink();
        return {
            hasLink,
            linkTag,
            properties,
        };
    },

    data() {
        return {
            dragingHandle: 'start',
            dragingIndex: -1,

            style: this.getStyle(),
            direction: this.getDirection(),
        };
    },
    computed: {
        tag() {
            return this.hasLink ? this.linkTag : 'div';
        },
        screenSize() {
            return this.wwFrontState.screenSize;
        },
        isBound() {
            // eslint-disable-next-line no-unreachable
            return false;
        },
        isEmpty() {
            // eslint-disable-next-line no-unreachable
            return false;
        },
        isEditing() {
            // eslint-disable-next-line no-unreachable
            return false;
        },
        wwObjectFlex() {
            const style = {};
            const isFlex = this.content.type !== 'mosaic' || this.content.alignItems === 'stretch';
            style.flexGrow = isFlex ? '1' : 'unset';
            if (this.content.type === 'columns') style.alignSelf = 'auto';
            return style;
        },
        layoutStyle() {
            return {
                flexDirection: this.direction,
                ...this.style,
            };
        },
        children() {
            if (!this.content.children || !Array.isArray(this.content.children)) {
                return [];
            }
            return this.content.children;
        },
    },
    watch: {
        /* wwFront:start */
        screenSize(newVal, oldVal) {
            if (newVal !== oldVal) {
                this.style = this.getStyle();
                this.direction = this.getDirection();
            }
        },
        /* wwFront:end */

    },
    mounted() {
    },
    methods: {
        getItemStyle(index) {
            const style = {
                flexShrink: 'unset',
                justifyContent: '',
            };

            //Reverse
            if (this.content.reverse) {
                style.order = this.children.length - 1 - index;
            } else {
                style.order = index;
            }

            //Push last
            if (this.content.pushLast) {
                const push = !this.content.reverse ? index === this.children.length - 1 : index === 0;
                if (push) {
                    if (this.content.direction === 'column') {
                        style.marginTop = 'auto';
                    } else {
                        style.marginLeft = 'auto';
                    }
                }
            }

            if (this.content.type !== 'rows') {
                const widthInUnit = this.getGridAt(index);
                style.width = `calc(${widthInUnit} * 100% / ${this.content.lengthInUnit})`;
                style.flexShrink = '0';
            } else {
                style.width = `100%`;
            }

            if (
                this.content.type === 'mosaic' &&
                this.content.alignItems !== 'stretch' &&
                this.content.alignItems !== 'baseline'
            ) {
                style.justifyContent = this.content.alignItems;
            }

            return style;
        },
        getStyle() {
            return {
                flexWrap: this.content.type === 'mosaic' ? 'wrap' : 'unset',
                justifyContent: this.content.type === 'mosaic' ? this.content.justifyContent : 'unset',
                alignItems: this.content.type === 'mosaic' ? this.content.alignItems : 'unset',
            };
        },
        getDirection() {
            return this.content.type === 'rows' ? 'column' : 'row';
        },
        getInheritFromElement() {
            return this.content.type === 'mosaic' ? ['width', 'display'] : [];
        },
        getWwObjectFlex() {
            const isFlex = this.content.type !== 'mosaic' || this.content.alignItems === 'stretch';
            return isFlex ? '1' : 'unset';
        },
        getGridAt(index, grid) {
            index = this.isBound ? 0 : index;
            grid = grid || this.content.grid;
            if (!grid) return 1;
            if (index >= grid.length) {
                return grid[0] || 1;
            } else {
                return grid[index];
            }
        },
        fit(list, grid) {
            if (this.isBound) return;
            if (this.content.type !== 'columns') return;
            const totalGrid = list.reduce((total, item, i) => total + this.getGridAt(i) || 0, 0);
            const lengthInUnit = this.content.lengthInUnit;
            if (totalGrid === lengthInUnit && list.length === grid.length) return grid;

            const count = Math.max(1, list.length);
            const itemLength = Math.floor(lengthInUnit / count);
            const firstItemLength = lengthInUnit - (count - 1) * itemLength;

            return list.map((_, index) => {
                return index === 0 ? firstItemLength : itemLength;
            });
        },
        async update(event) {
        },
        moveItem(grid, fromIndex, toIndex) {
            const list = [...grid];
            const [item] = list.splice(fromIndex, 1);
            if (fromIndex < toIndex) toIndex--;
            list.splice(toIndex, 0, item);
            return list;
        },
    },
};
</script>

<style lang="scss" scoped>
.ww-columns {
    position: relative;
    box-sizing: border-box;

    &.-link {
        cursor: pointer;
    }

    &__dropzone {
        display: flex;
        height: 100%;
        width: 100%;
    }

    &__column {
        position: relative;
        display: flex;
        flex-direction: column;

    }

}
</style>
