import { memo } from 'react'
import ReactMarkdown, { type Components } from 'react-markdown'
import rehypeHighlight from 'rehype-highlight'
import remarkGfm from 'remark-gfm'
import { CodeBlock } from './CodeBlock.tsx'

type Props = {
  text: string
}

const remarkPlugins = [remarkGfm]
const rehypePlugins = [rehypeHighlight]
const blocked = ['img']
const components: Components = {
  a: ({ node: _node, ...props }) => <a {...props} target="_blank" rel="noreferrer noopener" />,
  pre: ({ node: _node, ...props }) => <CodeBlock {...props} />,
}

export const Markdown = memo(function Markdown({ text }: Props) {
  return (
    <div className="markdown">
      <ReactMarkdown remarkPlugins={remarkPlugins} rehypePlugins={rehypePlugins} components={components} disallowedElements={blocked}>
        {text}
      </ReactMarkdown>
    </div>
  )
})
