import glob
import markdown
import os
import re
import shutil
import sys
import yaml

from jinja2 import Environment, FileSystemLoader


class Renderer:
    dir_configs = 'configs/'
    dir_index = 'index/'
    dir_out = 'upload/'
    dir_pages = 'pages/'
    dir_snippets = 'snippets/'
    dir_static = 'static/'

    def __init__(self):
        self.configs = type('', (object,), {
            'main': {},
            # TODO: iterate through snippets dir
            'snippets': {
                'article': self.raw_snippet('article.html'),
                'bg': self.raw_snippet('bg.html'),
                'js_core': self.raw_snippet('js-core.html'),
                'meta': self.raw_snippet('meta.html'),
                'nav': self.raw_snippet('nav.html'),
                'page_list': self.raw_snippet('page-list.html'),
                'style': self.raw_snippet('style.html'),
            }
            # TODO: add full/merged config here
        })()
        with open(self.dir_configs + 'main.yml', 'r') as f:
            self.configs.main = yaml.safe_load(f)

        self.envs = type('', (object,), {
            'snippets': Environment(loader=FileSystemLoader('snippets')),
            'templates': Environment(loader=FileSystemLoader('templates')),
            'textual': Environment(),
        })()

        self.pre_baked_blog_overview = self.pre_bake('blog-overview.html')
        self.pre_baked_page = self.pre_bake('page.html')

    # - - - - - actions - - - - -
    def all(self):
        # copy static assets
        shutil.copytree(
            src=self.dir_static,
            dst=self.dir_out,
            dirs_exist_ok=True
        )
        shutil.copytree(
            src=self.dir_static,
            dst=self.dir_index,
            dirs_exist_ok=True
        )
        # create pages dict
        pages = {}
        for page in os.listdir(self.dir_pages):
            md = page + '.md'
            shutil.copytree(
                src=self.dir_pages + page + '/assets',
                dst=self.dir_out + 'assets',
                dirs_exist_ok=True
            )
            with open(self.dir_pages + page + '/' + md) as f:
                # TODO: extract categories and use as filterable classes
                pages[page] = {
                    'name': page,
                    'md': md,
                    'title': f.readline().rstrip()[2:],
                    'date': find_in_file_stream(f, r'^\d').split(',')[0],
                    # TODO: maybe should pre-bake pages separately
                    'content': '',
                    'bg_src': glob.glob(self.dir_pages + page + '/assets/*-bg.*')[0].split('/')[-1],
                }
                pages[page]['bg_title'] = pages[page]['bg_src'].split('.')[0].replace('-', ' ').rsplit(' ', 1)[0]
                f.seek(0, 0)
                pages[page]['content'] = markdown.markdown(f.read())
        # create blog overview
        with open(self.dir_index + 'blog-overview.html', 'w') as f:
            values = self.configs.main | {
                'page': {
                    'title': 'Blog Overview'
                },
                'pages': pages.values(),
            }
            f.write(
                self.render(
                    self.text(self.pre_baked_blog_overview), values
                )
            )
        # process pages
        for _, page in pages.items():
            values = self.configs.main | {'page': page}
            with open(self.dir_out + page['name'], 'w') as f:
                # TODO: introduce convenience function for text/string render
                f.write(
                    self.render(
                        self.text(
                            self.render(
                                self.text(self.pre_baked_page), values
                            )
                        ), values
                    )
                )
        return 0

    # - - - - - complex helpers - - - - -
    def pre_bake(self, key):
        template = self.template(key)
        values = self.configs.snippets
        return self.render(template, values)

    # - - - - - simple helpers - - - - -
    # TODO: not sure if we need this => maybe should pre-bake all pages separately?
    def md(self, key):
        with open(self.dir_pages + key, 'r') as markdown_file:
            return markdown.markdown(markdown_file.read())

    def raw_snippet(self, key):
        with open(self.dir_snippets + key, 'r') as f:
            return f.read()

    # TODO: consider making this a static function
    def render(self, template, values):
        return template.render(values=values)

    def snippet(self, key):
        return self.envs.snippets.get_template(key)

    def template(self, key):
        return self.envs.templates.get_template(key)

    def text(self, text):
        return self.envs.textual.from_string(text)


def find_in_file_stream(stream, regex):
    for line in stream:
        if re.match(regex, line):
            return line.rstrip()


if __name__ == '__main__':
    renderer = Renderer()
    # sys.exit(update_env_vars(sys.argv[1]))
    sys.exit(renderer.all())
