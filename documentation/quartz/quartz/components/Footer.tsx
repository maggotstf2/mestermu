import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "./types"
import style from "./styles/footer.scss"
import { version } from "../../package.json"
import { i18n } from "../i18n"

interface Options {
  links: Record<string, string>
}

export default ((opts?: Options) => {
  const Footer: QuartzComponent = ({ displayClass, cfg }: QuartzComponentProps) => {
    const year = new Date().getFullYear()
    const links = opts?.links ?? []
    return (
      <footer class={`${displayClass ?? ""}`}>
        <p>
          {i18n(cfg.locale).components.footer.createdWith}{" "}
          <a href="https://quartz.jzhao.xyz/">Quartz v{version}</a> © {year}
        </p>
        <ul>
            <li>
              <a href="https://github.com/maggotstf2/mestermu">GitHub</a>
            </li>
            <li>
              <a href="https://tormabiztonsagtechnika.hu/">Back to website</a>
            </li>
        </ul>
        <ul style={{ marginTop: "0.25rem" }}>
            <li>
              Czéh Szabolcs
            </li>
            <li>
              Gonda Ákos
            </li>
            <li>
              Torma Enikõ
            </li>
        </ul>
      </footer>
    )
  }

  Footer.css = style
  return Footer
}) satisfies QuartzComponentConstructor
